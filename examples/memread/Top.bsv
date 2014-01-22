// bsv libraries
import SpecialFIFOs::*;
import Vector::*;
import StmtFSM::*;
import FIFO::*;

// portz libraries
import AxiClientServer::*;
import Directory::*;
import CtrlMux::*;
import Portal::*;
import PortalMemory::*;
import PortalRMemory::*;
import AxiRDMA::*;

// generated by tool
import MemreadRequestWrapper::*;
import DMARequestWrapper::*;
import MemreadIndicationProxy::*;
import DMAIndicationProxy::*;

// defined by user
import Memread::*;

module mkPortalTop(StdPortalDmaTop#(addrWidth)) provisos (
    Add#(addrWidth, a__, 52),
    Add#(b__, addrWidth, 64),
    Add#(c__, 12, addrWidth),
    Add#(addrWidth, d__, 44));

   DMAIndicationProxy dmaIndicationProxy <- mkDMAIndicationProxy(9);

   MemreadIndicationProxy memreadIndicationProxy <- mkMemreadIndicationProxy(7);
   Memread memread <- mkMemread(memreadIndicationProxy.ifc);
   MemreadRequestWrapper memreadRequestWrapper <- mkMemreadRequestWrapper(1008,memread.request);

   Vector#(1, DMAReadClient#(64)) clients = cons(memread.dmaClient, nil);
   Integer             numRequests = 2;
   AxiDMAServer#(addrWidth,64) dma <- mkAxiDMAServer(dmaIndicationProxy.ifc, numRequests, clients, nil);

   DMARequestWrapper dmaRequestWrapper <- mkDMARequestWrapper(1005,dma.request);

   Vector#(4,StdPortal) portals;
   portals[0] = memreadRequestWrapper.portalIfc;
   portals[1] = memreadIndicationProxy.portalIfc; 
   portals[2] = dmaRequestWrapper.portalIfc;
   portals[3] = dmaIndicationProxy.portalIfc; 
   
   Directory dir <- mkDirectory(portals);
   Vector#(1,StdPortal) directories;
   directories[0] = dir.portalIfc;
   
   // when constructing ctrl and interrupt muxes, directories must be the first argument
   let ctrl_mux <- mkAxiSlaveMux(directories,portals);
   let interrupt_mux <- mkInterruptMux(portals);
   
   interface interrupt = interrupt_mux;
   interface ctrl = ctrl_mux;
   interface m_axi = replicate(dma.m_axi);
   interface leds = ?;
endmodule : mkPortalTop
