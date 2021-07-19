/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.4;

// Adding ERC-20 tokens function for added balanceOfcontract Token {
//contract Token {
    //function transfer(address _to, uint _value) public returns (bool success);
    //function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    //function approve(address _spender, uint _value) public returns (bool success);
//}

// Adding only ERC-20 DAI functions that we need //0x727C4e8577b315C87697810e4fE4a27efC5463c6

interface Token {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
    function transferFrom(address _from, address _to, uint _value)external view returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address owner, address spender) external returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface INFT {
    function arbitratorAddress() external view returns(address);
    function ownerAddress() external view returns(address);
    function getTokenOwner  (string memory _id) external view returns (address);
    function mintNFT(string memory tokenUri, string memory _id) external returns (uint256);
    function mintNFTSave(string memory tokenUri, string memory _id, address to) external returns (uint256);
    function internalTransfer(address to, string memory _id, bytes32 data) external returns(bool success);
    function directTransfer(address to, string memory _id) external returns(uint256);
    function userTokens(address to) external;
    function burn (string memory _id) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function approveTokenToAddress(address to, string memory _id) external;
    function getTotalTokenOwner(address to) external view returns(uint256);
}

contract Dai{
    Token daitoken;

    constructor(){
        daitoken =  Token(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);     // Kovan
        //daitoken = DaiInterface(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);    // Rinkeby
        //daitoken = DaiInterface(0x6B175474E89094C44Da98b954EedeAC495271d0F);    // ETH Mainnet
        //daitoken = DaiInterface(0x6B175474E89094C44Da98b954EedeAC495271d0F);    // BSC Mainnet
    }
}

contract Treks{
    Token trekstoken;

    constructor(){
        trekstoken = Token(0x15492208Ef531EE413BD24f609846489a082F74C);
    }
}


contract PlayTreksMarketPlace is Dai, Treks {
    address public creator = msg.sender; // can withdraw funds after the successful is successfully funded and finished
    uint public start = block.timestamp;
    uint public end = block.timestamp + 60; // 1 min 
    Logs[] public trans;
    address[] public arbitrator;
    address public owner;
    address public relayer;
    uint32 public requestCancellationMinimumTime;
    uint256 public feesAvailableForWithdraw;

    struct Client {
        uint amountSent;
        bool exists;
        uint clientIndex;
    }
    
    struct Logs{
        address receiver;
        uint256 amount;
    }
    
    struct Escrow {
        // Set so we know the trade has already been created
        bool exists;
        // 1 = unlimited cancel time
        uint32 sellerCanCancelAfter;
        // The total cost of gas spent by relaying parties. This amount will be
        // refunded/paid to playtreks once the escrow is finished.
        uint128 totalGasFeesSpentByRelayer;
        // nft address for the escrow
        bytes32 nft;
        
        //GenNFTInterface genft; //contract for the nft contract
    }

    mapping(address => Client) public clientStructs;
    // Mapping of active trades. Key is a hash of the trade data
    mapping (bytes32 => Escrow) public escrows;
    mapping(address=> uint) public shares;
    address[] public clientList;
    
    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);
    event Returned(address indexed to, uint amount);
    event Balance(uint amount);
    event Created(bytes32 _tradeHash);
    event SellerCancelDisabled(bytes32 _tradeHash);
    event SellerRequestedCancel(bytes32 _tradeHash);
    event CancelledBySeller(bytes32 _tradeHash);
    event CancelledByBuyer(bytes32 _tradeHash);
    event Released(bytes32 _tradeHash);
    event DisputeResolved(bytes32 _tradeHash);
    
    constructor (){
        owner = msg.sender;
        arbitrator.push(msg.sender);
        relayer = msg.sender;
        requestCancellationMinimumTime =  1 hours;
    }
    
    //frontend
    function buywithEth(uint256 agreedAmount, string memory _id, address nftContract) payable public {
        uint256 amount = msg.value;
        require(amount > 0, "You need to send some ether");
        require(amount >= agreedAmount, "Not enough Eth sent for purchase of nft");
        
        INFT Nft;  //initialize Nft object to pull function from contract after intitialization here
        Nft = INFT(nftContract);
        
        //transfer the nft to the new owner
        Nft.directTransfer(msg.sender, _id);

        address currentOwner = Nft.getTokenOwner(_id);
        //pay to nft owner account and taxes and royalties
        if(Nft.ownerAddress() == msg.sender){
            currentOwner.call{value: (amount*95)/100}("");
            //trekstoken.transfer(owner, (amount*95)/100)
        }else{
            currentOwner.call{value: (amount*90)/100}("");
            Nft.ownerAddress().call{value: (amount*5)/100}("");
            //trekstoken.transfer(owner, (amount*90)/100)
            //trekstoken.transfer(original, (amount*5)/100)
        }

        //address treksWallet = 0x05b2DCeDEe832Ba4ae7631cD1fF6E5Fc2c88037C;
        //pay remaining commision to PlayTreks wallet
        owner.call{value: (amount*5)/100}("");
        //trekstoken.transfer(0x05b2DCeDEe832Ba4ae7631cD1fF6E5Fc2c88037C, (amount/5))

    }
    
    //frontend
    function buyWithToken(uint256 amount, string memory _id,  address nftContract, bool types) public{
        require(amount > 0, "You need to send at least some tokens");
        uint256 allowance = trekstoken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        
        INFT Nft;  //initialize Nft object to pull function from contract after intitialization here
        Nft = INFT(nftContract);
        address currentOwner = Nft.getTokenOwner(_id);

        // types == true means treks token is used for payment, false means dai token is used for payment
        if(types == true){
            //receive payment for nft
            trekstoken.transferFrom(msg.sender, currentOwner, amount);
            
            //transfer the nft to the new owner
            Nft.directTransfer(msg.sender, _id);

            //pay to nft owner account and taxes and royalties
            if(Nft.ownerAddress() == msg.sender){
                trekstoken.transfer(currentOwner, (amount*95)/100);
            }else{
                trekstoken.transfer(currentOwner, (amount*90)/100);
                trekstoken.transfer(Nft.ownerAddress(), (amount*5)/100);
            }
    
            //pay remaining commision to PlayTreks wallet
            trekstoken.transfer(owner, (amount/5));
        }else{
            //receive payment for nft
            daitoken.transferFrom(msg.sender, currentOwner, amount);
            
            //transfer the nft to the new owner
            Nft.directTransfer(msg.sender, _id);
    
            //pay to nft owner account and taxes and royalties
            if(Nft.ownerAddress() == msg.sender){
                daitoken.transfer(currentOwner, (amount*95)/100);
            }else{
                daitoken.transfer(currentOwner, (amount*90)/100);
                daitoken.transfer(Nft.ownerAddress(), (amount*5)/100);
            }
    
            //pay remaining commision to PlayTreks wallet
            daitoken.transfer(owner, (amount/5));
        }
        
    }

    // create an escrow (backend)
    function createEscrow(
      /**
       * Create a new escrow and add it to `escrows`.
       * _tradeHash is created by hashing _tradeID, _buyer, _value and _fee variables. These variables must be supplied on future contract calls.
       * v, r and s is the signature data supplied from the api. The sig is keccak256(_tradeHash, _paymentWindowInSeconds, _expiry).
       */
      string memory _tradeID, // The unique ID of the trade, generated by app.playtreks api
      address _buyer, // The buying party of the trade
      uint256 _value, // The ether amount being held in escrow
      uint16 _fee, // The PlayTreks fee in 1/10000ths
      uint32 _paymentWindowInSeconds, // The time in seconds from contract creation that the buyer has to mark as paid //15*60
      //uint32 _expiry, // Provided by playtreks. This transaction must be created before this time.
      bytes32 _nft_hash
      //uint8 _v, // Signature value
      //bytes32 _r, // Signature value
      //bytes32 _s // Signature value from web3.eth.accounts.sign()
    ) public {
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeID, _buyer, _value, _fee));
        require(!escrows[_tradeHash].exists); // Require that trade does not already exist
        //require(ecrecover(keccak256(abi.encodePacked(_tradeHash, _paymentWindowInSeconds, _expiry)), _v, _r, _s) == relayer); // Signature must have come from the relayer
        //require(block.timestamp < _expiry);
        //require(msg.value == _value && msg.value > 0); // Check sent eth against signed _value and make sure is not 0
        uint32 _sellerCanCancelAfter = _paymentWindowInSeconds == 0 ? 1 : uint32(block.timestamp) + _paymentWindowInSeconds;
        //GenNFTInterface gen = addNft(_nft_address);
        escrows[_tradeHash] = Escrow(true, _sellerCanCancelAfter, 0, _nft_hash);
        emit Created(_tradeHash);
    }
    
    
    function getEscrowAndHash(
      /**
       * Hashes the values and returns the matching escrow object and trade hash.
       * Returns an empty escrow struct and 0 _tradeHash if not found
       */
      string memory _tradeID,
      address _buyer,
      uint256 _value,
      uint16 _fee
    ) view public returns (Escrow memory, bytes32) {
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeID, _buyer, _value, _fee) );
        return (escrows[_tradeHash], _tradeHash);
    }
    
    function getEscrowFromHash(
      /**
       * send the trade hash and get the matching escrow object and trade hash.
       * Returns an empty escrow struct and 0 _tradeHash if not found
       */
      bytes32 _tradeHash
    ) view public returns (Escrow memory, bytes32) {
        return (escrows[_tradeHash], _tradeHash);
    }
    
    uint16 constant GAS_doDisableSellerCancel = 12100;
    function doDisableSellerCancel(
      /**
       * Stops the seller from cancelling the trade.
       * Can only be called by the buyer.
       * Used to mark the trade as paid, or if the buyer has a dispute.
       */
      string memory _tradeID,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
        PlayTreksMarketPlace.Escrow memory _escrow;
        bytes32 _tradeHash;
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        if(_escrow.sellerCanCancelAfter == 0) return false;
        escrows[_tradeHash].sellerCanCancelAfter = 0;
        emit SellerCancelDisabled(_tradeHash);
        if (msg.sender == relayer) {
          increaseGasSpent(_tradeHash, GAS_doDisableSellerCancel + _additionalGas);
        }
        return true;
    }
    
    uint16 constant GAS_doBuyerCancel = 36100;
    function doBuyerCancel(
      /**
       * Cancels the trade and returns the item to the seller.
       * Can only be called by the buyer.
       */
      string memory _tradeID,
      address _buyer,
      uint256 _value,
      uint16 _fee
      //uint128 _additionalGas
    ) private returns (bool) {
        PlayTreksMarketPlace.Escrow memory _escrow;
        bytes32 _tradeHash;
        
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        //uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer ? (GAS_doBuyerCancel + _additionalGas) * uint128(tx.gasprice) : 0);
        delete escrows[_tradeHash];
        emit CancelledByBuyer(_tradeHash);
        //transferMinusFees(_seller, _value, _gasFees, 0);
        return true;
    }

    uint16 constant GAS_doSellerCancel = 36100;
    function doSellerCancel(
      /**
       * Cancels the trade and returns the ether to the seller.
       * Can only be called the seller.
       * Can only be called if the payment window was missed by the buyer
       */
      string memory _tradeID,
      address _buyer,
      uint256 _value,
      uint16 _fee
      //uint128 _additionalGas
    ) private returns (bool) {
        PlayTreksMarketPlace.Escrow memory _escrow;
        bytes32 _tradeHash;
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        if(_escrow.sellerCanCancelAfter <= 1 || _escrow.sellerCanCancelAfter > block.timestamp) return false;
        //uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer ? (GAS_doSellerCancel + _additionalGas) * uint128(tx.gasprice) : 0);
        delete escrows[_tradeHash];
        emit CancelledBySeller(_tradeHash);
        //transferMinusFees(_seller, _value, _gasFees, 0);
        return true;
    }
    
    function transferMinusFees(address _to, uint256 _value, uint128 _totalGasFeesSpentByRelayer, uint16 _fee) private {
        uint256 _totalFees = (_value * _fee / 10000) + _totalGasFeesSpentByRelayer;
        if(_value - _totalFees > _value) return; // Prevent underflow
        feesAvailableForWithdraw += _totalFees; // Add the the pot for playtreks to withdraw
        daitoken.transfer(_to, _value - _totalFees);
    }
    
    //function transferNft(address _to, string memory _id, uint256 _value, uint128 _totalGasFeesSpentByRelayer, uint16 _fee, Escrow memory _escrow) private {
        //uint256 _totalFees = (_value * _fee / 10000) + _totalGasFeesSpentByRelayer;
        //if(_value - _totalFees > _value) return; // Prevent underflow
        //feesAvailableForWithdraw += _totalFees; // Add the the pot for playtreks to withdraw
        //_escrow.genft.transfer(_to, _id);
    //}
    
    uint16 constant GAS_doSellerRequestCancel = 12100;
    function doSellerRequestCancel(
      /**
       * Called by the seller if the buyer is unresponsive
       * Can only be called on unlimited payment window trades (sellerCanCancelAfter == 1)
       * Sets the payment window to `requestCancellationMinimumTime` from now, in which it can be cancelled.
       */
      string memory _tradeID,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
        // Called on unlimited payment window trades where the buyer is not responding
        PlayTreksMarketPlace.Escrow memory _escrow;
        bytes32 _tradeHash;
        
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        if(_escrow.sellerCanCancelAfter != 1) return false;
        escrows[_tradeHash].sellerCanCancelAfter = uint32(block.timestamp) + requestCancellationMinimumTime;
        emit SellerRequestedCancel(_tradeHash);
        if (msg.sender == relayer) {
          increaseGasSpent(_tradeHash, GAS_doSellerRequestCancel + _additionalGas);
        }
        return true;
    }

    uint16 constant GAS_doResolveDispute = 36100;
    function resolveDispute(
      /**
       * Called by the arbitrator to resolve a dispute
       * Requires the signed ACTION_DISPUTE actionByte from either the buyer or the seller
       */
      string memory _tradeID,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint8 _buyerPercent,
      uint types
    ) external onlyArbitrator {
        //address _signature = ecrecover(keccak256(abi.encodePacked(_tradeID, ACTION_DISPUTE)), _v, _r, _s);
        //require(_signature == _buyer || _signature == _seller);
        
        PlayTreksMarketPlace.Escrow memory _escrow;
        bytes32 _tradeHash;
    
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _buyer, _value, _fee);
        require(_escrow.exists);
        require(_buyerPercent <= 100);

        uint256 _totalFees = _escrow.totalGasFeesSpentByRelayer + GAS_doResolveDispute;
        require(_value - _totalFees <= _value); // Prevent underflow
        feesAvailableForWithdraw += _totalFees; // Add the the pot for localethereum to withdraw

        delete escrows[_tradeHash];
        emit DisputeResolved(_tradeHash);
        if (types == 0){
            daitoken.transfer(_buyer, (_value - _totalFees) * _buyerPercent / 100);
        }else if(types == 1){
            address payable to = payable(_buyer);
            to.transfer((_value - _totalFees) * _buyerPercent / 100);
        }
        //daitoken.transfer(_seller, (_value - _totalFees) * (100 - _buyerPercent) / 100);
    }
    
    
    uint16 constant GAS_doRelease = 36100;
    function doRelease(
      /**
       * Called by the seller to releases the funds for a successful trade.
       * Deletes the trade from the `escrows` mapping.
       */
      string memory _tradeID,
      address _buyer,
      uint256 _value,
      uint16 _fee
    ) private returns (bytes32) {
        PlayTreksMarketPlace.Escrow memory _escrow;
        bytes32 _tradeHash;
        
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _buyer, _value, _fee);
        if (!_escrow.exists) return 0x0;
        //uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer ? (GAS_doRelease + _additionalGas) * uint128(tx.gasprice) : 0);
        //transferNft(_buyer, _tradeID, _value, _gasFees, _fee, escrows[_tradeHash]);
        delete escrows[_tradeHash];
        emit Released(_escrow.nft);
        
        return _escrow.nft;
    }
    
    //function confirmPurchase(address user, uint256 fee) public view returns(bool){
        //if(clientStructs[user].exists && clientStructs[user].amountSent == fee) return true;
        //if(clientStructs[user].exists) return true;
        
        //return false;
    //}
    
    //either fe or be
    function release(string memory _tradeID,  address _buyer, uint256 _value, uint16 _fee, address _nftContract) onlyCreator(_nftContract) external returns (bytes32){
      //require(msg.sender == _seller);
      return doRelease(_tradeID, _buyer, _value, _fee);
    }
    function disableSellerCancel(string memory _tradeID,  address _buyer, uint256 _value, uint16 _fee) external returns (bool) {
      require(msg.sender == _buyer || msg.sender == owner);
      return doDisableSellerCancel(_tradeID, _buyer, _value, _fee, 100);
    }
    function buyerCancel(string memory _tradeID, address _buyer, uint256 _value, uint16 _fee) external returns (bool) {
      require(msg.sender == _buyer || msg.sender == owner);
      return doBuyerCancel(_tradeID, _buyer, _value, _fee);
    }
    function sellerCancel(string memory _tradeID, address _buyer, uint256 _value, uint16 _fee) onlyArbitrator external returns (bool) {
      //require(msg.sender == _seller);
      return doSellerCancel(_tradeID, _buyer, _value, _fee);
    }
    function sellerRequestCancel(string memory _tradeID, address _buyer, uint256 _value, uint16 _fee) onlyArbitrator external returns (bool) {
      //require(msg.sender == _seller);
      return doSellerRequestCancel(_tradeID, _buyer, _value, _fee, 100);
    }

    
    function increaseGasSpent(bytes32 _tradeHash, uint128 _gas) private {
        /** Increase `totalGasFeesSpentByRelayer` to be charged later on completion of the trade.
         */
        escrows[_tradeHash].totalGasFeesSpentByRelayer += _gas * uint128(tx.gasprice);
    }
    
    function setArbitrator(address _newArbitrator) onlyArbitrator external {
        /**
         * Set the arbitrator to a new address. Only the owner can call this.
         * @param address _newArbitrator
         */
        arbitrator.push(_newArbitrator);
    }

    function setOwner(address _newOwner) onlyArbitrator external {
        /**
         * Change the owner to a new address. Only the owner can call this.
         * @param address _newOwner
         */
        owner = _newOwner;
    }

    function setRelayer(address _newRelayer) onlyArbitrator external {
        /**
         * Change the relayer to a new address. Only the owner can call this.
         * @param address _newRelayer
         */
        relayer = _newRelayer;
    }

    function setRequestCancellationMinimumTime(uint32 _newRequestCancellationMinimumTime) onlyArbitrator external {
        /**
         * Change the requestCancellationMinimumTime. Only the owner can call this.
         * @param uint32 _newRequestCancellationMinimumTime
         */
        requestCancellationMinimumTime = _newRequestCancellationMinimumTime;
    }

    function contractAddress() public view returns(address){
        return address(this);
    }

    modifier onlyArbitrator {
        bool yes = false;
        for (uint i=0; i<arbitrator.length; i++) {
            if(msg.sender == arbitrator[i]){
                yes=true;
            }
        }
        require(yes == true, "Only approved arbitrators can call this function");
        _;
    }
    
    // modifier so that only the project creator can call certain functions
    modifier onlyCreator (address _contract){
        INFT Nft;  //initialize Nft object to pull function from contract after intitialization here
        Nft = INFT(_contract);
        
        bool yes = false;
        for (uint i=0; i<arbitrator.length; i++) {
            if(msg.sender == arbitrator[i]){
                yes=true;
            }
        }
        
        require (Nft.ownerAddress() == msg.sender || Nft.arbitratorAddress() == msg.sender || yes == true, "Unauthorized");
        _;
    }
}