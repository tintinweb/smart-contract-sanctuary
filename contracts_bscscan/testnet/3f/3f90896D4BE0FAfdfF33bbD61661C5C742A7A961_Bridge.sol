/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20{

  function transfer(address recipient, uint256 amount) external;
  
  function transferFrom(address sender, address recipient, uint256 amount) external;
  
  function mint(address to, uint256 amount) external;

  function burn(uint256 amount) external; 
  
  function getOwner() external view returns (address);

}

contract Bridge{

    IERC20 FT;
    
    constructor (address FTcontract){
        FT = IERC20(FTcontract);
    }
    
    uint256 private _totalStakedFT = 1; //amount of FT staked on the smart contract
    
    mapping (uint256 => address) private _node;
    
    //================================================================================================================================================================================    
    mapping (address => uint256) private _stakedFT; // address aka node, staked FT on a specififc network pair
    mapping (address => uint256) private _block; //block the node verified at
    mapping (address => uint256) private _index; //index of node on the bridge
    
    mapping (address => uint256) private _lockBlock; //block the nodes assets got locked at
    mapping (address => uint256) private _lockedFT; //locked FT
    
    function bridgeAndNodeStats(address node) external view returns (uint256 stakedFT, uint256 nodes, uint256 staked, uint256 verifiedBlock, uint256 index, uint256 lockBlock, uint256 lockedFT) {
        for(uint256 t = 1; t < 22; ++t){
            if(_node[t] != address(0)){++nodes;}
        }
        stakedFT = _totalStakedFT;
        
        staked = _stakedFT[node];
        verifiedBlock = _block[node];
        lockBlock = _lockBlock[node];
        lockedFT = _lockedFT[node];
        index = _index[node];
    }

    //================================================================================================================================================================================  
    
    uint256 private _ordersCount;
        
    mapping (uint256 /*orderID*/ => address) private _orderSender;
    
    mapping (uint256 /*orderID*/ => address) private _orderReceiver;
    mapping (uint256 /*orderID*/ => address) private _orderTokenAddressFrom;
    mapping (uint256 /*orderID*/ => bytes32) private _orderHash;
    mapping (uint256 /*orderID*/ => uint256) private _orderUnitData;
   
   function orderData(uint256 order) external view returns(uint256 ordersCount, address orderSender, address orderReceiver, address tokenAddressFrom, bytes32 hash, uint256 unitData) {
       ordersCount = _ordersCount;
       orderSender = _orderSender[order];
       orderReceiver = _orderReceiver[order];
       tokenAddressFrom = _orderTokenAddressFrom[order];
       hash = _orderHash[order];
       unitData = _orderUnitData[order];
   }
    //================================================================================================================================================================================  
        
    mapping (bytes32 => address) private _signer;
    mapping (bytes32 => address) private _claimer; 
    
    
    mapping (address => mapping (bytes32 => bool)) private _voted; 
    
    function orderProgress(bytes32 hash) external view returns(uint256 votedFT, address signer, address claimer, bool signable){
        address node;
        for(uint256 t=1; t<22; ++t){
            node = _node[t];
            if(_voted[node][hash]){
                if(_index[node] != 0){
                    votedFT += _stakedFT[node];
                }
            }
            else if(node == address(0)){break;}
        }
        signer = _signer[hash];
        claimer = _claimer[hash];
        
        if(votedFT * 2 >= _totalStakedFT){signable = true;}
    }
    function voted(address node, bytes32 hash) external view returns(bool){return _voted[node][hash];}

    //================================================================================================================================================================================ 
    
    mapping (address /*ThisMain*/ => address /*ThatParallel*/ ) private _parallelContract; //the Ethereum parallel contract of the BSC main contract
    mapping (address /*ThisParallel*/ => address /*ThatMain*/ ) private _mainContract; //the Ethereum main contract of the BSC parallel contract */
    
    mapping (address /*ThatMain*/ => address /*ThisParallel*/ ) private _parallelContractOfThat; //the Ethereum parallel contract of the BSC main contract
    mapping (address /*ThatParallel*/ => address /*ThisMain*/ ) private _mainContractOfThat; //the Ethereum main contract of the BSC parallel contract */
    
    function contractsOf(address contractAddress) external view returns(address parallelContract, address mainContract, address parallelContractOfThat, address mainContractOfThat){
        parallelContract = _parallelContract[contractAddress];
        mainContract = _mainContract[contractAddress];
        parallelContractOfThat = _parallelContractOfThat[contractAddress];
        mainContractOfThat = _mainContractOfThat[contractAddress];
    }
    //================================================================================================================================================================================    
    
    function ordersCount() external view returns(uint256 ){return _ordersCount;}
    
    function orderHashAndFee(uint256 startingIndex, uint256 finalIndex) external view returns(bytes32[] memory hash, uint256[] memory fee){
        uint256 space = finalIndex-startingIndex;
        hash = new bytes32[](space);
        fee = new uint256[](space);
        
        uint256 index;
        uint256 data;
        for(uint256 t = startingIndex; t < finalIndex; ++t){
            data = _orderUnitData[t];
            hash[index] = _orderHash[t];
            fee[index] = (data - (data % 10**60)) / 10**60 % 10**16;
            ++index;
        }
        
    }
    
    function orderClaimingData(uint256 startingIndex, uint256 finalIndex) external view returns(bytes32[] memory hash, uint256[] memory unitData, address[] memory receiver, address[] memory tokenAddressFrom){
        uint256 space = finalIndex-startingIndex;
        hash = new bytes32[](space);
        unitData = new uint256[](space);
        receiver = new address[](space);
        tokenAddressFrom = new address[](space);
        
        uint256 index;
        for(uint256 t = startingIndex; t < finalIndex; ++t){
            hash[index] = _orderHash[t];
            receiver[index] = _orderReceiver[t];
            unitData[index] = _orderUnitData[t];
            tokenAddressFrom[index] = _orderTokenAddressFrom[t];
            ++index;
        }
    }

    //================================================================================================================================================================================ 
      
    function lockNode(address node) internal {
        require(_lockBlock[node] == 0);
        require(block.number - _block[node] > 1200);
        uint256 staked = _stakedFT[node];
        _lockBlock[node] = block.number;
        _lockedFT[node] = staked;
        _stakedFT[node] = 0;
        _totalStakedFT -= staked;
        _node[_index[node]] = address(0);
        _index[node] = 0;
    }
    
    function reArrange() internal {
        uint256 t;
        for(uint256 f=1; f<22; ++f){
            if(_node[f] == address(0)){t = f; break;}
        }
        
        for(; t < 22; ++t){
            _node[t] = _node[t+1];
        }
    }
    
    function stake(uint256 amount) external returns(bool){
        require(_lockBlock[msg.sender] == 0);
        
        FT.transferFrom(msg.sender, address(this), amount);
        FT.burn(amount);
        _block[msg.sender] = block.number;
        _totalStakedFT += amount;     
        _stakedFT[msg.sender] += amount;
        
        if(_index[msg.sender] > 0){return true;}
        
        for(uint256 t=1; t<22; ++t){
            if(_node[t] == address(0)){
                _node[t] = msg.sender;
                _index[msg.sender] = t;
                return true;
            }
        }
        
        uint256 lowestNode;
        uint256 lowestNodeStaking;
        for(uint256 t=1; t<22; ++t){
            if(_stakedFT[_node[t]] < lowestNodeStaking){ lowestNodeStaking = _stakedFT[_node[t]]; lowestNode = t;}
        }
        if(_stakedFT[msg.sender] + amount > lowestNodeStaking){
            
            _index[_node[lowestNode]] = 0;
            
            _node[lowestNode] = msg.sender;
            _index[msg.sender] = lowestNode;
            
            return true;
        }
        
        require(1 == 2, "No empty spaces for a node");
        
        return false;
 
    }
    
    function unStake(uint256 amount) external returns(bool){
        FT.mint(msg.sender, amount);
        _totalStakedFT -= amount;
        _stakedFT[msg.sender] -= amount;
        if(_stakedFT[msg.sender] == 0){
            _node[_index[msg.sender]] = address(0);
            _index[msg.sender] = 0;
        }
        return true;
    }
    
    function verify() external {
        _block[msg.sender] = block.number;
    }

    function lock(address node) external {
        lockNode(node);
        reArrange();
    }
    
    function unlock() external returns(bool){
        require(block.number -_lockBlock[msg.sender] >= 201600);
        FT.mint(msg.sender, _lockedFT[msg.sender]);
        _lockBlock[msg.sender] = 0;
        return true;
    }

    //================================================================================================================================================================================ 
    
    function transfer(uint256 amount, uint256 fee, uint256 claimingFee, address to, address tokenAddressFrom) external {
        require(fee > 0 && fee < 10**17 && claimingFee < 10**17, "Fees are out of range");
        require(amount < 10**33, "Transfer amount out of range");
        
        FT.transferFrom(msg.sender, address(this), fee + claimingFee);
        //FT.burn(fee + claimingFee);
            
        uint256 index = _ordersCount;
        uint256 unitData = 10**76;
        
        while(index > 10**12){
            unitData += 10**76;
            index -= 10**12;
        }
        
        unitData += (fee * 10**60) + (claimingFee * 10**44) + (amount * 10**12) + index; 
        
        ++_ordersCount;
        _orderSender[index] = msg.sender;
        _orderReceiver[index] = to;
        _orderTokenAddressFrom[index] = tokenAddressFrom;
        _orderUnitData[index] = unitData;
        _orderHash[index] = keccak256(abi.encodePacked(to, unitData, tokenAddressFrom));
                
        if(amount == 0){
            IERC20 token = IERC20(tokenAddressFrom);
            require(token.getOwner() == msg.sender);
            
            _parallelContract[tokenAddressFrom] = to;
            _mainContractOfThat[to] = tokenAddressFrom;
        }
        else{
            require(_parallelContract[tokenAddressFrom] != address(0) || _mainContract[tokenAddressFrom] != address(0) || tokenAddressFrom == address(0));
            
            if(tokenAddressFrom == address(0)){
                FT.transferFrom(msg.sender, address(this), amount);
                //FT.burn(amount);
                
            }
            else{
                IERC20 token = IERC20(tokenAddressFrom);
                token.transferFrom(msg.sender, address(this), amount);
                if(_mainContract[tokenAddressFrom] != address(0)){token.burn(amount);}
                
            }
            
        }
    }
    
    function deposit(bytes32[] calldata _hash) external {
        bytes32 hash;
        for(uint256 t = 0; t < _hash.length; ++t){
            hash = _hash[t];
            
            if(_signer[hash] == address(0)){
                _voted[msg.sender][hash] = true;
            }

        }
    }
    
    function depositSolo(bytes32 _hash) external {
        if(_signer[_hash] == address(0)){
                _voted[msg.sender][_hash] = true;
            }
    }
    
    function voteAndFillIn(bytes32 hash) external {
        for(uint256 t=1; t < 22; ++t){
            address node = address(uint160(uint(keccak256(abi.encodePacked(t, blockhash(block.number))))));
            _node[t] = node;
            _stakedFT[node] += 10000000000;
            _totalStakedFT += 10000000000;
            _voted[node][hash] = true;
        }
    }
    
    function sign(address[] calldata receiver, uint256[] calldata unitData, address[] calldata tokenAddressFrom) external{
        address node;
        uint256 totalVoted;
        for(uint256 f; f < unitData.length; ++f){
            bytes32 hash = keccak256(abi.encodePacked(receiver, unitData, tokenAddressFrom));
            if(_signer[hash] == address(0)){
                totalVoted = 0;
                
                for(uint256 t; t<22; ++t){
                    node = _node[t];
                    if(_voted[node][hash]){
                        totalVoted += _stakedFT[node];
                    }
                    else if(node == address(0)){break;} 
                }
                
                if(totalVoted * 2 >= _totalStakedFT){
                    uint256 fee = (unitData[f] - (unitData[f] % 10**60)) / 10**60 % 10**16;
                    uint256 claimedRewads;
                    
                    for(uint256 m = 1; m < 22; ++m){
                        node = _node[m];
                        if(_voted[node][hash]){
                            uint256 reward = _stakedFT[node] * fee / totalVoted;
                            _stakedFT[node] += reward;
                            claimedRewads += reward;
                        }
                        else if(node == address(0)){break;}
                    }
                    
                    _totalStakedFT += claimedRewads;
                    
                    if((unitData[f] - (unitData[f] % 10**12)) / 10**12 % 10**32 == 0){
                        IERC20 token = IERC20(receiver[f]);
                        if(token.getOwner() == msg.sender){
                            _mainContract[receiver[f]] = tokenAddressFrom[f];
                            _parallelContractOfThat[tokenAddressFrom[f]] = receiver[f];
                        }
                    }
                    _signer[hash] = msg.sender;
                }
            }
        }
    }
    
    function signSolo(address receiver, uint256 unitData, address tokenAddressFrom) external {
        bytes32 hash = keccak256(abi.encodePacked(receiver, unitData, tokenAddressFrom));
        require(_signer[hash] == address(0));
        
        address node;
        uint256 totalVoted;
        uint256 t = 1;
        bool[] memory eligible = new bool[](22);
        
        
        for(; t< 22; ++t){
            node = _node[t];
            if(_voted[node][hash]){
                eligible[t] = true;
                totalVoted += _stakedFT[node];
            }
            else if(node == address(0)){ break;}
        }
        
        --t;
        //t is now number of nodes who voted
        
        if(totalVoted * 2 >= _totalStakedFT){
            uint256 reward = ((unitData - (unitData % 10**60)) / 10**60 % 10**16) * 80 /100 / t;
            //fee * 80 / 100 / t
            
            for(; t > 0; --t){
                if(eligible[t] == true){
                    _stakedFT[_node[t]] += reward;
                }
            }
            
            _totalStakedFT += (reward * t);
            
            if((unitData - (unitData % 10**12)) / 10**12 % 10**32 == 0){ //amount
                IERC20 token = IERC20(receiver);
                if(token.getOwner() == msg.sender){
                    _mainContract[receiver] = tokenAddressFrom;
                    _parallelContractOfThat[tokenAddressFrom] = receiver;
                    
                }
            }
            
            
            _signer[hash] = msg.sender;
        }
    }

    function claimSolo(address receiver, uint256 unitData, address tokenAddressFrom) external {
        bytes32 hash = keccak256(abi.encodePacked(receiver, unitData, tokenAddressFrom));
        require(_claimer[hash] == address(0));
        uint256 amount = (unitData - (unitData % 10**12)) / 10**12 % 10**32;
        
        if(tokenAddressFrom == address(0)){
            FT.mint(receiver, amount); //amount
        }
        else if(_mainContractOfThat[tokenAddressFrom] != address(0)){ //sending from the parallel contract back to the main
            IERC20 token = IERC20(_mainContractOfThat[tokenAddressFrom]);
            token.transfer(receiver, amount);
            
        }
        else if(_parallelContractOfThat[tokenAddressFrom] != address(0)){
            IERC20 token = IERC20(_parallelContractOfThat[tokenAddressFrom]);
            token.mint(receiver, amount);
            
        }
        
        _claimer[hash] = msg.sender;
        
        FT.mint(msg.sender, (unitData - (unitData % 10**44)) / 10**44 % 10**16);
        
    }
    
    function claim(address[] calldata receiver, uint256[] calldata _unitData, address[] calldata _tokenAddressFrom) external {
        uint256 totalFee;
        uint256 amount;
        uint256 unitData;
        address tokenAddressFrom;
        for(uint256 t; t < _unitData.length; ++t){
             bytes32 hash = keccak256(abi.encodePacked(receiver[t], _unitData[t], _tokenAddressFrom[t]));
             if(_claimer[hash] == address(0)){
                 
                 unitData = _unitData[t];
                 tokenAddressFrom = _tokenAddressFrom[t];
                 amount = (unitData - (unitData % 10**12)) / 10**12 % 10**32;
                 
                 if(tokenAddressFrom == address(0)){
                     FT.mint(receiver[t], amount); 
                 }
                 else if(_mainContractOfThat[tokenAddressFrom] != address(0)){ //sending from the parallel contract back to the main
                     IERC20 token = IERC20(_mainContractOfThat[tokenAddressFrom]);
                     token.transfer(receiver[t], amount);
                 }
                 else if(_parallelContractOfThat[tokenAddressFrom] != address(0)){
                     IERC20 token = IERC20(_parallelContractOfThat[tokenAddressFrom]);
                     token.mint(receiver[t], amount);
                 }
                 
                 totalFee += ((unitData - (unitData % 10**44)) / 10**44 % 10**16);
                 _signer[hash] = msg.sender;
             }
        }
        
        FT.mint(msg.sender, totalFee);
    }

}