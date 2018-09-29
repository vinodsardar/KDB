\p 1234
services:([handle:`int$()]address:`$();source:`$();gwHandle:`int$();sq:`int$();udt:`timestamp$());

serviceQueue:([gwHandle:`int$();sq:`int$()]source:`$();time:`timestamp$()); 

gateways:();

registerGW:{gateways,:.z.w ; select source, address from services};
registerResource:{[name;addr]`services upsert (.z.w;addr;name;0N;0N;.z.p);(neg gateways)@\:(`addResource;enlist`source`address!(name;addr)); serviceAvailable[.z.w;name]};


sendService:{[gw;h]neg[gw]raze(`serviceAlloc;services[h;`sq`address])};


requestService:{[seq;serv]res:exec first handle from services where source=serv,null gwHandle; $[null res;addRequestToQueue[seq;serv;.z.w]; [services[res;`gwHandle`sq`udt]:(.z.w;seq;.z.p);sendService[.z.w;res]]]};

addRequestToQueue:{[seq;serv;gw]`serviceQueue upsert (gw;seq;serv;.z.p)};

returnService:{serviceAvailable . $[.z.w in (0!services)`handle;(.z.w;x);value first select handle,source from services where gwHandle=.z.w,sq=x]}


serviceAvailable:{[zw;serv]nxt:first n:select gwHandle,sq from serviceQueue where source=serv;serviceQueue::(1#n)_ serviceQueue;services[zw;`gwHandle`sq`udt]:(nxt`gwHandle;nxt`sq;.z.p);if[count n;sendService[nxt`gwHandle;zw]]};

.z.pc:{[h]services _:h;gateways::gateways except h;delete from `serviceQueue where gwHandle=h;update gwHandle:0N from `services where gwHandle=h };