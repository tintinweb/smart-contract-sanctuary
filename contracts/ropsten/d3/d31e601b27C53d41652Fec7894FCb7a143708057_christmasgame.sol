pragma solidity ^0.5.0;

contract christmasgame {

    ///////CONTRACT STATES 


    // Defining giver structure
    struct giver{
        string givername;
        string givergift;
        address giveraddress;
    }
    
    giver[] public giverarray; // will contain givers
    
    // Defining receiver structure
    struct receiver{
        string receivername;
        address receiveraddress;
    }
    
    receiver[] public receiverarray; // will contain receivers
    
    // Defining selector structure
    struct selector{
        string selectorname;
        address selectoraddress;
    }
    
    selector public firstselector; // will contain first selector to let him be the last receiver
    
    
    bool public isregistrationphaseclosed = false; // it&#39;s a boolean that defines if this phase is closed
    
    // this account will decide who will be the first selector
    address constant public gamemaster = 0x935D3a60C5b8E2204CCc4fBdb171559DEF0CCcb4;
     
    // this will contain the current selector
    selector public currentselector;
    
    // this will contain the current giver
    giver public currentgiver;
    
    // this will contain the current receiver
    receiver public currentreceiver;
    
    
    
    ///////CONTRACT FUNCTIONS
    
    constructor () public {
        
    }
    
    
    //permits to add giver name and giver gift
    function addmeandmygift(string memory myname, string memory mygift) public {

        // only if registration phase is still open
        if (isregistrationphaseclosed==false) {
            // take name and gift and put in structure "giver", together with address
            giver memory newgiver = giver({givername: myname, givergift: mygift, giveraddress: msg.sender});
            // take receiver name and put in structure "receiver", together with address 
            receiver memory newreceiver = receiver({receivername: myname, receiveraddress: msg.sender});
        
            // put newly created giver in table of givers
            giverarray.push(newgiver);
            // put newly created receiver in the table of receivers
            receiverarray.push(newreceiver);
       
        }  
        
    }
    
    // this function will define first selector
    function closeregistrationphaseandchoosefirstselector(address firstselectoraddress) public {
        //check if registration phase is still open and if the caller is the game master 
        if (isregistrationphaseclosed==false && msg.sender==gamemaster) {
        
            //close registration phase
            isregistrationphaseclosed=true;
    

            
            //put first selector apart until the end
            // search in receiver list
            uint receiverarraylength = receiverarray.length; // getting array length
            for (uint i = 0; i < receiverarraylength; i = i+1) { // for each receiver in array
                receiver memory testedreceiver = receiverarray[i]; // getting candidate receiver
                // if we found the receiver in the list
                if (testedreceiver.receiveraddress==firstselectoraddress){
                    // take from list and put apart as first selector
                    firstselector.selectorname = testedreceiver.receivername; // copying name
                    firstselector.selectoraddress = testedreceiver.receiveraddress; // copying adress
                    
                    // remove from receiver list
                    receiverarray[i]=receiverarray[receiverarraylength-1];
                    receiverarray.length--;
            
                    break;
                }
            
            }
            
            //choose first selector
            currentselector = firstselector;
            
        
         
        }
        
    }
    
        
    // this function will permit to the current selector to choose the current giver and the current receiver
    function currentselectorchoosegiverandreceiver(address currentgiveraddress,address currentreceiveraddress) public {
        // this function can be called only by the current selector! so we check if the caller is the current selector
        if ( isregistrationphaseclosed==true && currentselector.selectoraddress==msg.sender){ // if the caller is the current selector, and if the registration phase is closed
        
                // choose current giver
                // search in givers list
                uint giverarraylength = giverarray.length; // getting array length
                for (uint i = 0; i < giverarraylength; i = i+1) { // for each giver in array
                    // if we found the giver in the list
                    giver memory testedgiver = giverarray[i]; // getting candidate giver
                    if (testedgiver.giveraddress==currentgiveraddress){
                        // take from list and put in current giver
                        currentgiver = giverarray[i];
                    
                        // remove from givers list
                        giverarray[i]=giverarray[giverarraylength-1];
                        giverarray.length--;
                        
                        break;
                    }
                }
            
            // if there are remaining receiver, taking receiver from function call. Otherwhise, it is the last round, so the first selector gets the last gift
           if (receiverarray.length>0){ // if there are remaining receivers
            
                // choose current receiver
                // search in givers list
                uint receiverarraylength = receiverarray.length; // getting array length
                for (uint i = 0; i < receiverarraylength; i = i+1) { // for each receiver in array
                
                    receiver memory testedreceiver = receiverarray[i]; // getting candidate receiver
                    // if we found the receiver in the list
                    if (testedreceiver.receiveraddress==currentreceiveraddress){
                        // take from list and put in current receiver
                        currentreceiver = receiverarray[i];
                    
                        // remove from receiver list
                        receiverarray[i]=receiverarray[receiverarraylength-1];
                        receiverarray.length--;
                        
                        break;            
                    }
            
                }
            
            
                // current receiver becomes current selector 
                currentselector.selectorname = currentreceiver.receivername; // copy name
                currentselector.selectoraddress = currentreceiver.receiveraddress; // copy address
        
            } else { // if the receivers list is empty - last round
        
                // first selector becomes last receiver
                currentreceiver.receivername = firstselector.selectorname; // copy name
                currentreceiver.receiveraddress = firstselector.selectoraddress; // copy adress
        
                // no more currentselector to assign, game is finished
                currentselector.selectorname = "Nobody!";
                currentselector.selectoraddress = address(0);
                
            
            
            }
        
        
        }
   
    }
    
    
    
     
}