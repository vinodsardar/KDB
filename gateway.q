\p 5555
manageConn:{@[{NLB::neg LB::hopen x};`:localhost:1234;{show x}]}; 
registerGWFunc:{addResource LB(`registerGW;`)};


resources:([address:()] source:();sh:());
addResource:{`resources upsert `address xkey update sh:{hopen first x}'[address] from x};

queryTable:([sq:`int$()];uh:`int$();rec:`timestamp$();
  snt:`timestamp$();
  ret:`timestamp$();
  user:`$();
  sh:`int$();
  serv:`$();
  query:());

  userQuery:{
  $[(serv:x 0) in exec distinct source from resources; // Check if valid service
    [queryTable,:(SEQ+:1;.z.w;.z.p;0Np;0Np;.z.u;0N;serv;x 1); 
      NLB(`requestService;SEQ;serv)];
    (neg .z.w)(`$"Service Unavailable")]};

    serviceAlloc:{[sq;addr]
  $[null queryTable[sq;`uh];
  // Check if user is still waiting on results
    NLB(`returnService;sq);
  // Service no longer required
    [(neg sh:resources[addr;`sh]) (`queryService;(sq;queryTable[sq;`query]));
  // Send query to allocated resource, update queryTable
      queryTable[sq;`snt`sh]:(.z.p;sh)]]};

returnRes:{[res]uh:first exec uh from queryTable where sq=(res 0); 
  // (res 0) is the sequence number
  if[not null uh;(neg uh)(res 1)];
  // (res 1) is the result
  queryTable[(res 0);`ret]:.z.p
  };

  .z.pc:{[handle]
  // if handle is for a user process, set the query handle (uh) as null
  update uh:0N from `queryTable where uh=handle;
  // if handle is for a resource process, remove from resources
    delete from `resources where sh=handle;
  // if any user query is currently being processed on the service which 
  // disconnected, send message to user
  if[count sq:exec distinct sq from queryTable where sh=handle,null ret;
    returnRes[sq cross `$"Service Disconnect"]]; 
  if[handle~LB; // if handle is Load Balancer
    // Send message to each connected user, which has not received results
    (neg exec uh from queryTable where not null uh,null snt)@\: `$"Service Unavailable";
    // Close handle to all resources and clear resources table
    hclose each (0!resources)`sh;
    delete from `resources;
    // update queryTable to close outstanding user queries
    update snt:.z.p,ret:.z.p from `queryTable where not null uh,null snt; 
    // reset LB handle and set timer of 10 seconds
    // to try and reconnect to Load Balancer process
    LB::0; NLB::0; value"\\t 10000"]};

.z.ts:{
  manageConn[]; if[0<LB;@[registerGWFunc;`;{show x}];value"\\t 0"]
  }; 

.z.ts[];