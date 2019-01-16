pragma solidity ^0.5.1;

contract RelayDelivery {
    mapping(address => bool) enabledRelays; // Solidity bool default is false
    mapping(bytes32 => address payable) private deliveryLedger;
    mapping(bytes32 => bool) private deliveryStatus; // Solidity bool default is false
    mapping(address => bool) private relayBusy; // Solidity bool default is false
    mapping(address => mapping(bytes32 => package)) private packageRecord;
    mapping(bytes32 => uint256) private packageFuel; // Hey Solidity, I want f*king tuples ;)
    mapping(bytes32 => uint256) private packageFuelRemaining; // Hey Solidity, I want f*king tuples ;)
    address payable private owner;
    
    uint256 private onFlight = 0; // Packages being delivered, for control, ideally payout and base fee would be updated only when onFligh == 0
    
    uint256 private payoutAmount = 100; // Payout amount is fixed (updatable) in RelayDelivery v1, all delivery 
                                        // guys are assigned to an area of similar size and difficulty,
                                        // delivery guys can take a single package at a time
                                        
    uint256 private baseFee = 100; // Base fee
                                        
    constructor() public{
        owner = msg.sender;
    }
    
    function Destroy() public payable{
        require(owner == msg.sender, "You are not the owner!");
        selfdestruct(owner);
    }
    
    function owner_updateBaseFee(uint256 _baseFee) public {
        require(owner == msg.sender, "You are not the owner!");
        baseFee = _baseFee;
    }
    
    function owner_updatePayout(uint256 _payout) public {
        require(owner == msg.sender, "You are not the owner!");
        payoutAmount = _payout;
    }
    
    function owner_loadFunds() public payable {
        require(owner == msg.sender, "You are not the owner!");
    }
    
    function owner_viewOnFlight() public view returns(uint256) {
        require(owner == msg.sender, "You are not the owner!");
        return onFlight;
    }
    
    function owner_updateRelay(address _relay, bool _enabled) public {
        require(owner == msg.sender, "You are not the owner!");
        enabledRelays[_relay] = _enabled;
    }
    
    function owner_viewStatus(string memory _code, address _sender,
        string memory _senderAddress, string memory _receiverAddress, address _receiver) public view 
        returns (bool _status, uint256 _fuel, uint256 _fuelRemaining, address _relay) {
            
        require(owner == msg.sender, "You are not the owner!");
        
        // Only for readability, ABI encoder does not support structs in main
        // (it does in experimental, will change contract code once released)
        // DEV WARNING: timestamp would be hashed with the new ABI encoder
        
        package memory p = package ({
            code: _code,
            sender: _sender,
            senderAddress: _senderAddress,
            receiverAddress: _receiverAddress,
            receiver: _receiver,
            timestamp: 0
        });

        
        bytes32 packageHash = keccak256(abi.encodePacked(p.code, p.sender, p.senderAddress, p.receiverAddress, p.receiver));
        
        _status = deliveryStatus[packageHash];
        _fuel = packageFuel[packageHash];
        _fuelRemaining = packageFuelRemaining[packageHash];
        _relay = deliveryLedger[packageHash];
    }
    
    function owner_updateFuel(uint256 fuel, string memory _code, address _sender,
        string memory _senderAddress, string memory _receiverAddress, address _receiver) public {

        require(owner == msg.sender, "You are not the owner!");
        
        // Only for readability, ABI encoder does not support structs in main
        // (it does in experimental, will change contract code once released)
        // DEV WARNING: timestamp would be hashed with the new ABI encoder
        
        package memory p = package ({
            code: _code,
            sender: _sender,
            senderAddress: _senderAddress,
            receiverAddress: _receiverAddress,
            receiver: _receiver,
            timestamp: 0
        });

        
        bytes32 packageHash = keccak256(abi.encodePacked(p.code, p.sender, p.senderAddress, p.receiverAddress, p.receiver));
        
        require(!deliveryStatus[packageHash], "Package has been delivered!"); // Package is being delivered
        require(packageFuelRemaining[packageHash] <= (packageFuel[packageHash] / 2), "Point of no return not yet reached!"); // Point of no return
                                                                                                                             // Also checks if package "exists"
        packageFuel[packageHash] += fuel;
    }
    
    function viewBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function sender_requestDelivery(string memory _code, string memory _senderAddress,
                            string memory _receiverAddress, address _receiver) public payable {
        
        require(msg.value > baseFee, "Fuel too low!"); // Do not accept less than base service fee
                
        // Only for readability, ABI encoder does not support structs in main
        // (it does in experimental, will change contract code once released)
        // DEV WARNING: timestamp would be hashed with the new ABI encoder
        
        package memory p = package ({
            code: _code,
            sender: msg.sender,
            senderAddress: _senderAddress,
            receiverAddress: _receiverAddress,
            receiver: _receiver,
            timestamp: now
        });
        

        
        bytes32 packageHash = keccak256(abi.encodePacked(p.code, p.sender, p.senderAddress, p.receiverAddress, p.receiver));
        
        require(deliveryLedger[packageHash] == address(0x0), "Package is not new!"); // Package is new

        deliveryLedger[packageHash] = msg.sender; // Package is with sender
        deliveryStatus[packageHash] = false; // Package is in delivery loop
        
        packageRecord[msg.sender][packageHash] = p;
        packageFuel[packageHash] = msg.value;
        packageFuelRemaining[packageHash] = msg.value;
        
        onFlight++;
    }
    
    function sender_getReceipt(string memory __code,
    string memory __senderAddress, string memory __receiverAddress, address __receiver) public view
    returns(string memory _code, address _sender, string memory _senderAddress,
    string memory _receiverAddress, address _receiver, uint256 _timestamp) {
        
        package memory p = package ({
            code: __code,
            sender: msg.sender,
            senderAddress: __senderAddress,
            receiverAddress: __receiverAddress,
            receiver: __receiver,
            timestamp: 0
        });
        
        bytes32 packageHash = keccak256(abi.encodePacked(p.code, p.sender, p.senderAddress, p.receiverAddress, p.receiver));
        
        package memory q = packageRecord[msg.sender][packageHash];
        
        _code = q.code;
        _sender = q.sender;
        _senderAddress = q.senderAddress;
        _receiverAddress = q.receiverAddress;
        _receiver = q.receiver;
        _timestamp = q.timestamp;
    }
    
    function receiver_updateLedger(string memory _code, address _sender, string memory _senderAddress,
                                    string memory _receiverAddress, address _receiver) public payable {
        
        // Only for readability, ABI encoder does not support structs in main
        // (it does in experimental, will change contract code once released)
        // DEV WARNING: timestamp would be hashed with the new ABI encoder
        
        package memory p = package ({
            code: _code,
            sender: _sender,
            senderAddress: _senderAddress,
            receiverAddress: _receiverAddress,
            receiver: _receiver,
            timestamp: 0
        });

        
        bytes32 packageHash = keccak256(abi.encodePacked(p.code, p.sender, p.senderAddress, p.receiverAddress, p.receiver));
        
        require(!deliveryStatus[packageHash], "Package has been delivered!"); // Package is being delivered
        require(packageFuelRemaining[packageHash] > (packageFuel[packageHash] / 2), "Point of no return reached, not enough fuel!"); // Point of no return
                                                                                                                                     // Also checks if package "exists"
        packageFuel[packageHash] -= payoutAmount;
        
        address payable holder = deliveryLedger[packageHash]; // Stores current holder&#39;s address
        
        require(enabledRelays[msg.sender] || p.receiver == msg.sender, "You are not allowed to receive the package!"); // Checks if relay is enabled,
                                                                                                                       // prevents attacks on the public blockchain
        
        require(holder != msg.sender, "Can&#39;t relay the package to yourself!");  // Prevents multiple payments to same delivery guy, 
                                                                                // does not prevent multiple payments between different
                                                                                // delivery guys, logic to prevent this has to be 
                                                                                // implemented somewhere else for v1
                                                                                // EDIT: see below
        
        require(!packageRecord[p.sender][packageHash].relayRecord[msg.sender],
        "Can&#39;t route the package through the same relay twice!"); // Prevents a package being routed twice through the same relay

        if(holder != p.sender) { // First delivery guy takes the package from sender
            require(relayBusy[holder], "You are not the carrier anymore!"); // Prevents reentrancy using chained attacker contracts 
            relayBusy[holder] = false; // Prevents reentrancy using chained attacker contracts
        } else {
            deliveryStatus[packageHash] = false; // Package is being delivered -- redundant
        }
        
        packageRecord[p.sender][packageHash].relayRecord[msg.sender] = true; // Sets the relay visited to true
        deliveryLedger[packageHash] = msg.sender; // Next delivery guy takes the package
        
        if(msg.sender != p.receiver) {
            relayBusy[msg.sender] = true; // Prevents reentrancy using chained attacker contracts
        } else {
            deliveryStatus[packageHash] = true; // Package delivered
            onFlight--;
        }
        
        if(holder != p.sender) { // First delivery guy takes the package from sender
            holder.transfer(payoutAmount); // Previous delivery guy gets paid
        }
        
    }
    
    function sender_viewStatus(string memory _code,
        string memory _senderAddress, string memory _receiverAddress, address _receiver) public view 
        returns (bool _status, uint256 _fuel, uint256 _fuelRemaining) {
        
        // Only for readability, ABI encoder does not support structs in main
        // (it does in experimental, will change contract code once released)
        // DEV WARNING: timestamp would be hashed with the new ABI encoder
        
        package memory p = package ({
            code: _code,
            sender: msg.sender,
            senderAddress: _senderAddress,
            receiverAddress: _receiverAddress,
            receiver: _receiver,
            timestamp: 0
        });

        
        bytes32 packageHash = keccak256(abi.encodePacked(p.code, p.sender, p.senderAddress, p.receiverAddress, p.receiver));
        
        _status = deliveryStatus[packageHash];
        _fuel = packageFuel[packageHash];
        _fuelRemaining = packageFuelRemaining[packageHash];
    }
    
    function receiver_viewStatus(string memory _code, address _sender,
        string memory _senderAddress, string memory _receiverAddress) public view 
        returns (bool _status) {
        
        // Only for readability, ABI encoder does not support structs in main
        // (it does in experimental, will change contract code once released)
        // DEV WARNING: timestamp would be hashed with the new ABI encoder
        
        package memory p = package ({
            code: _code,
            sender: _sender,
            senderAddress: _senderAddress,
            receiverAddress: _receiverAddress,
            receiver: msg.sender,
            timestamp: 0
        });

        
        bytes32 packageHash = keccak256(abi.encodePacked(p.code, p.sender, p.senderAddress, p.receiverAddress, p.receiver));
        
        _status = deliveryStatus[packageHash];
    }
    
    // Package data gets scanned from QR code in package
    struct package {
        string code;
        address sender;
        string senderAddress;
        string receiverAddress;
        address receiver;
        uint256 timestamp;
        mapping(address => bool) relayRecord;
    }
    
}