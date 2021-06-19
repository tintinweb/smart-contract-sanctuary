/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

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
    
    uint256 private _totalStakedFT = 0; //amount of FT staked on the smart contract
    
    mapping (uint256 => address) private _node;
    
    //================================================================================================================================================================================    
    mapping (address => uint256) private _stakedFT; // address aka node, staked FT on a specififc network pair
    mapping (address => uint256) private _block; //block the node verified at
    mapping (address => uint256) private _index; //index of node on the bridge
    
    mapping (address => uint256) private _lockBlock; //block the nodes assets got locked at
    mapping (address => uint256) private _lockedFT; //locked FT
    //================================================================================================================================================================================
    uint256 private _sendOrdersCount = 0;
        
    mapping (uint256 /*orderID*/ => address) private _sendSender;
    mapping (uint256 /*orderID*/ => address) private _sendreceiver;
    mapping (uint256 /*orderID*/ => address) private _sendTokenAddressFrom;
    mapping (uint256 /*orderID*/ => uint256) private _sendAmount;
    mapping (uint256 /*orderID*/ => uint256) private _sendFee;
    mapping (uint256 /*orderID*/ => uint256) private _sendClaimingFee;
    //================================================================================================================================================================================  
    uint256 private _receiveOrdersCount = 1;
    
    mapping (uint256 => bool) private _processed; //if this transcation went through or not yet
    mapping (uint256 => bool) private _claimed;
    
    mapping(uint256 => address) private _creator;
    mapping(uint256 => address) private _signer;
    mapping (address => mapping (uint256 => bool)) private _voted; //if a node voted or not on this order
    mapping (uint256 => uint256) private _votedFT;
    
    mapping (address /*receiver*/ => mapping (uint256 /*amount*/ => mapping(uint256 /*fee*/ => mapping(uint256 /*claimingFee*/ => mapping (uint256 /*index*/ => mapping (address /*token Address From*/ => uint256 /*Index*/)))))) private _receiveOrderIndex;    
    //================================================================================================================================================================================
    uint256 private _addTokenRequests;
    
    mapping (uint256 => address) private _owner;
    mapping (uint256 => address) private _addTokenMainContract;
    mapping (uint256 => address) private _addTokenParallelContract;
    mapping (uint256 => uint256) private _addTokenFee;
    //================================================================================================================================================================================
    uint256 private _addTokenOrders = 1;
    
    mapping(address /*owner*/ => mapping(address /*main*/ => mapping (address /*parallel*/ => mapping (uint256 /*fee*/ => uint256)))) private _addTokenIndex;
    
    mapping(uint256 => address) private _addTokenCreator;
    mapping(uint256 => address) private _addTokenSigner;  
    mapping(uint256 => bool) private _addTokenClaim;
    
    mapping(address => mapping (uint256 => bool)) private _addTokenVoted;
    mapping(uint256 => uint256) private _addTokenVotedFT;
    
    mapping(uint256 => bool) private _addTokenProcessed;
    //================================================================================================================================================================================ 
    uint256 private _proposalsCount = 0;    
    
    mapping (uint256 => address) private _main;
    mapping (uint256 => address) private _parallel;
    mapping (uint256 => uint256) private _fee;
    mapping (uint256 => address) private _proposalCreator;
    mapping (uint256 => bool) private _signed;
    
    mapping (address => mapping (uint256 => bool)) private _proposalVoted; //if a node voted or not on this proposal
        
    //================================================================================================================================================================================ 
    
    mapping (address /*ThisMain*/ => address /*ThatParallel*/ ) private _parallelContract; //the Ethereum parallel contract of the BSC main contract
    mapping (address /*ThisParallel*/ => address /*ThatMain*/ ) private _mainContract; //the Ethereum main contract of the BSC parallel contract */
    
    mapping (address /*ThatMain*/ => address /*ThisParallel*/ ) private _parallelContractOfThat; //the Ethereum parallel contract of the BSC main contract
    mapping (address /*ThatParallel*/ => address /*ThisMain*/ ) private _mainContractOfThat; //the Ethereum main contract of the BSC parallel contract */
    
    mapping (address /*contract*/ => bool) private _full; //Fully inter blockchain
    
    function contractsOf(address contractAddress) external view returns(address parallelContract, address mainContract, address parallelContractOfThat, address mainContractOfThat, bool full){
        parallelContract = _parallelContract[contractAddress];
        mainContract = _mainContract[contractAddress];
        parallelContractOfThat = _parallelContractOfThat[contractAddress];
        mainContractOfThat = _mainContractOfThat[contractAddress];
        full = _full[contractAddress];
    }
    //================================================================================================================================================================================    

    function bridgeAndNodeStats(address node) external view returns (uint256 nodes, uint256 stakedFT, uint256 staked, uint256 verifiedBlock, uint256 locked, uint256 lockedFT, uint256 index){
        for(uint256 t = 1; t < 22; ++t){
            if(_node[t] != address(0)){++nodes;}
        }
        stakedFT = _totalStakedFT;
        
        staked = _stakedFT[node];
        verifiedBlock = _block[node];
        locked = _lockBlock[node];
        lockedFT = _lockedFT[node];
        index = _index[node];
    }
    function OrdersCount() external view returns(uint256 SendOrdersCount, uint256 ReceiveOrdersCount, uint256 RequestTokenOrdersCount, uint256 AddTokenOrdersCount, uint256 ProposalsCount){
        SendOrdersCount = _sendOrdersCount;
        ReceiveOrdersCount = _receiveOrdersCount - 1;
        RequestTokenOrdersCount = _addTokenRequests;
        AddTokenOrdersCount = _addTokenOrders - 1;
        ProposalsCount = _proposalsCount;
    }
    
    function doubleSendStats(uint256 ID, uint256 ID1) external view returns(address sender, address receiver, uint256 amount, uint256 fee, uint256 claimingFee, address tokenAddressFrom, address sender1, address receiver1, uint256 amount1, uint256 fee1, uint256 claimingFee1, address tokenAddressFrom1){
        sender = _sendSender[ID];
        receiver = _sendreceiver[ID];
        amount = _sendAmount[ID];
        fee = _sendFee[ID];
        claimingFee = _sendClaimingFee[ID];
        tokenAddressFrom = _sendTokenAddressFrom[ID];
        
        sender1 = _sendSender[ID1];
        receiver1 = _sendreceiver[ID1];
        amount1 = _sendAmount[ID1];
        fee1 = _sendFee[ID1];
        claimingFee1 = _sendClaimingFee[ID1];
        tokenAddressFrom1 = _sendTokenAddressFrom[ID1];
    }
    function addTokenAndProposalStats(uint256 ID, uint256 ID1) external view returns(address owner, address main, address parallel, uint256 fee, address creator, address main1, address parallel1, uint256 fee1, bool signed){
        owner = _owner[ID];
        main = _addTokenMainContract[ID];
        parallel = _addTokenParallelContract[ID];
        fee = _addTokenFee[ID];
        
        creator = _proposalCreator[ID1];
        main1 = _main[ID1];
        parallel1 = _parallel[ID1];
        fee1 = _fee[ID1];
        signed = _signed[ID1];
    }
    
    //deposit order and add order progress
    function orderProgress(address receiver, uint256 amount, uint256 fee, uint256 claimingFee, uint256 index, address tokenAddressFrom) external view returns(uint256 votedFT, bool processed, bool claimed){
        uint256 ID = _receiveOrderIndex[receiver][amount][fee][claimingFee][index][tokenAddressFrom];
        votedFT = _votedFT[ID];
        processed = _processed[ID];
        claimed = _claimed[ID];
    }
    function depositOrderProgress(address receiver, uint256 amount, uint256 fee, uint256 claimingFee, uint256 index, address tokenAddressFrom) external view returns(bool){
        return _processed[_receiveOrderIndex[receiver][amount][fee][claimingFee][index][tokenAddressFrom]];
    }
    function addTokenOrderProgress(address owner, address main, address parallel, uint256 fee) external view returns(bool signed){
        return _signed[_addTokenIndex[owner][main][parallel][fee]];
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
    
    function stake(uint256 amount) external returns(bool){
        require(_lockBlock[msg.sender] == 0);
        
        if(_index[msg.sender] > 0){
            FT.transferFrom(msg.sender, address(this), amount);
            _block[msg.sender] = block.number;
            _totalStakedFT += amount;     
            _stakedFT[msg.sender] += amount;
            
            return true;
        }
        
        for(uint256 t=1; t<22; ++t){
            if(_node[t] == address(0)){
                FT.transferFrom(msg.sender, address(this), amount);
                _block[msg.sender] = block.number;
                _totalStakedFT += amount;  
                _stakedFT[msg.sender] = amount;
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
            
            FT.transferFrom(msg.sender, address(this), amount);
                _block[msg.sender] = block.number;
                _totalStakedFT += amount;
                _stakedFT[msg.sender] += amount;
                _node[lowestNode] = msg.sender;
                _index[msg.sender] = lowestNode;
                
                return true;
        }
        
        for(uint256 t=1; t<22; ++t){
            if(block.number - _block[_node[t]] > 1200){
                FT.transferFrom(msg.sender, address(this), amount);
                _block[msg.sender] = block.number;
                _stakedFT[msg.sender] += amount;
                _node[t] = msg.sender;
                _index[msg.sender] = t;
                
                address node = _node[t];
                lockNode(node);
                
                _totalStakedFT += amount;
                
                return true;
            }
        }
        
        return false;
 
    }
    
    function unStake(uint256 amount) external returns(bool){
        FT.transfer(msg.sender, amount);
        _totalStakedFT -= amount;
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
    }
    
    function unlock() external returns(bool){
        require(block.number -_lockBlock[msg.sender] >= 201600);
        FT.transfer(msg.sender, _lockedFT[msg.sender]);
        _lockBlock[msg.sender] = 0;
        return true;
    }

    //================================================================================================================================================================================ 
    
    function signTransaction(uint256 ID, address signer, address receiver, uint256 amount, uint256 fee, uint256 claimingFee, address tokenAddressFrom) internal returns(bool) {
        uint256 totalVoted;
            
            for(uint256 t=1; t<22; ++t){
                if(_voted[_node[t]][ID]){
                    if(_index[_node[t]] != 0){totalVoted += _stakedFT[_node[t]];}
                }
            }
            
            if(totalVoted * 2 >= _totalStakedFT){
                uint256 claimedFees = fee * 10 / 100;
                if(_index[_creator[ID]] != 0){_stakedFT[_creator[ID]] += claimedFees;}
                else {claimedFees = 0;}
                uint256 distributionFee = fee - (claimedFees * 2);
                uint256 claimedPunishmentFees;
                
                for(uint256 t=1; t<22; ++t){
                    address node = _node[t];
                    if(_voted[node][ID]){
                            uint256 reward = _stakedFT[node] * distributionFee / totalVoted;
                            claimedFees += reward;
                            //_voted[node][ID] = false;
                            _stakedFT[node] += reward + 1000000000;
                            claimedPunishmentFees += 1000000000;
                    }
                }
                
                if(_index[signer] != 0){
                    _stakedFT[msg.sender] += (fee - claimedFees);
                    _totalStakedFT += fee + claimedPunishmentFees;
                }
                else{
                    FT.mint(signer, fee - claimedFees);
                    _totalStakedFT += fee - claimedFees + claimedPunishmentFees;
                }
                
                if(tokenAddressFrom == address(0)){
                    FT.mint(receiver, amount);
                    if(claimingFee > 0){_stakedFT[signer] += claimingFee;}
                    _claimed[ID] = true;
                }
                _signer[ID] = msg.sender;
                _processed[ID] = true;
                
                return true;
            }
            else{return false;}
    }
    
    function transfer(uint256 amount, uint256 fee, uint256 claimingFee, address to, address tokenAddressFrom) external {
        require(amount > 0);
        require(_parallelContract[tokenAddressFrom] != address(0) || _mainContract[tokenAddressFrom] != address(0) || tokenAddressFrom == address(0));
        
        uint256 index = _sendOrdersCount;
         
        if(tokenAddressFrom == address(0)){
            FT.transferFrom(msg.sender, address(this), fee + amount + claimingFee);
            FT.burn(fee + amount + claimingFee);
        }
        else{
            IERC20 token = IERC20(tokenAddressFrom);
            token.transferFrom(msg.sender, address(this), amount + claimingFee);
            FT.transferFrom(msg.sender, address(this), fee + claimingFee);
            if(_mainContract[tokenAddressFrom] != address(0) || _full[tokenAddressFrom]){token.burn(amount); FT.burn(fee);}
        }
        
        _sendSender[index] = msg.sender;
        _sendreceiver[index] = to;
        _sendAmount[index] = amount;
        _sendFee[index] = fee;
        _sendClaimingFee[index] = claimingFee;
        _sendTokenAddressFrom[index] = tokenAddressFrom;
        
        ++_sendOrdersCount;
    }
    
    function deposit(address receiver, uint256 amount, uint256 fee, uint256 claimingFee, uint256 index, address tokenAddressFrom) external {
        uint256 orderIndex = _receiveOrderIndex[receiver][amount][claimingFee][fee][index][tokenAddressFrom];
        require(!_processed[orderIndex]);
        require(_parallelContractOfThat[tokenAddressFrom] != address(0) || _mainContractOfThat[tokenAddressFrom] != address(0) || tokenAddressFrom == address(0));
        
            _stakedFT[msg.sender] -= 1000000000;
            _totalStakedFT -= 1000000000;
            
        if(orderIndex == 0){
            
            uint256 ordersCount = _receiveOrdersCount;
            
            _receiveOrderIndex[receiver][amount][fee][claimingFee][index][tokenAddressFrom] = ordersCount;
            
            _creator[ordersCount] = msg.sender;
            _voted[msg.sender][ordersCount] = true;
            _votedFT[ordersCount] = _stakedFT[msg.sender]; 
            
            orderIndex = ordersCount;
            _receiveOrdersCount += 1; 
            
        }
        else{
            require(!_voted[msg.sender][orderIndex]);
            
            _voted[msg.sender][orderIndex] = true;
            _votedFT[orderIndex] += _stakedFT[msg.sender]; 
        }
        
        if(_votedFT[orderIndex] * 2 >= _totalStakedFT){
            
            signTransaction(orderIndex, msg.sender, receiver, amount, fee, claimingFee, tokenAddressFrom);
        }

    }
    
    function claim(address receiver, uint256 amount, uint256 fee, uint256 claimingFee, uint256 index, address tokenAddressFrom) external {
        uint256 orderIndex = _receiveOrderIndex[receiver][amount][fee][claimingFee][index][tokenAddressFrom];
        require(!_claimed[orderIndex]);
        
        _claimed[orderIndex] = true;
        if(_processed[orderIndex]){
            if(_mainContractOfThat[tokenAddressFrom] != address(0)){ //sending from the parallel contract back to the main
                    IERC20 token = IERC20(_mainContractOfThat[tokenAddressFrom]);
                    token.transfer(receiver, amount);
            }
            else if(_parallelContractOfThat[tokenAddressFrom] != address(0)){ //sending from the main contract back to the parallel
                    IERC20 token = IERC20(_parallelContractOfThat[tokenAddressFrom]);
                    token.mint(receiver, amount);
            }
            FT.mint(msg.sender, claimingFee);
        }
        else{
            require(signTransaction(orderIndex, msg.sender, receiver, amount, fee, claimingFee, tokenAddressFrom));
                if(_mainContractOfThat[tokenAddressFrom] != address(0)){ //sending from the parallel contract back to the main
                    IERC20 token = IERC20(_mainContractOfThat[tokenAddressFrom]);
                    token.transfer(receiver, amount);
                }
                else if(_parallelContractOfThat[tokenAddressFrom] != address(0)){ //sending from the main contract back to the parallel
                    IERC20 token = IERC20(_parallelContractOfThat[tokenAddressFrom]);
                    token.mint(receiver, amount);
                }
            FT.mint(msg.sender, claimingFee);
        }
    }
    
    //================================================================================================================================================================================ 
    
    function requestToken(address main, address parallel, uint256 fee, bool full) external returns (uint256){
        IERC20 token = IERC20(main);
        require(token.getOwner() == msg.sender);
        return createTokenRequest(msg.sender, main, parallel, fee, full);
    }
    
    function addToken(address owner, address main, address parallel, uint256 fee) external {
        uint256 index = _addTokenIndex[owner][main][parallel][fee];
        require(!_addTokenProcessed[index]);
        require(!_addTokenVoted[msg.sender][index]);
        
        _stakedFT[msg.sender] -= 1000000000;
        _totalStakedFT -= 1000000000;
        
        if(index == 0){
            index = _addTokenOrders;
            ++_addTokenOrders;
            
            _addTokenCreator[index] = msg.sender;
            _addTokenVotedFT[index] = _stakedFT[msg.sender];
            _addTokenVoted[msg.sender][index] = true;
        }
        else{
            _addTokenCreator[index] = msg.sender;
            _addTokenVotedFT[index] += _stakedFT[msg.sender];
            _addTokenVoted[msg.sender][index] = true;
        }
        
        if(_addTokenVotedFT[index] * 2 >= _totalStakedFT){
            
            uint256 totalVoted;
            
            for(uint256 t=1; t<22; ++t){
                if(_addTokenVoted[_node[t]][index]){
                    totalVoted += _stakedFT[_node[t]];
                }
            }
            
            if(totalVoted * 2 >= _totalStakedFT){
                uint256 claimedFees = fee * 10 / 100;
                if(_index[_addTokenCreator[index]] != 0){_stakedFT[_addTokenCreator[index]] += claimedFees;}
                else {claimedFees = 0;}
                uint256 distributionFee = fee - (claimedFees * 2);
                uint256 claimedPunishmentFees;
                
                for(uint256 t=1; t<22; ++t){
                    address node = _node[t];
                    if(_addTokenVoted[node][index]){
                            uint256 reward = _stakedFT[node] * distributionFee / totalVoted;
                            claimedFees += reward;
                            _addTokenVoted[node][index] = false;
                            _stakedFT[node] += reward + 1000000000;
                            claimedPunishmentFees += 1000000000;
                    }
                }
                
                _stakedFT[msg.sender] += (fee - claimedFees);
                _totalStakedFT += fee + claimedPunishmentFees;
                
                _addTokenProcessed[index] = true;
                _addTokenSigner[index] = msg.sender;
                
                IERC20 token = IERC20(parallel);
                if(token.getOwner() == owner){
                    _mainContract[parallel] = main;
                    _parallelContractOfThat[main] = parallel;
                }
            }
        }
    }
    
    //================================================================================================================================================================================ 
    
    function createProposal(address ThisMain, address ThatParallel, uint256 fee) external returns(uint256) {
        FT.transferFrom(msg.sender, address(this), fee);
        FT.burn(fee);
        uint256 proposalsCount = _proposalsCount;
        _main[proposalsCount] = ThisMain;
        _parallel[proposalsCount] = ThatParallel;
        _fee[proposalsCount] = fee;
        _proposalCreator[proposalsCount] = msg.sender;
        ++_proposalsCount;
        return proposalsCount;
    }
    function voteOnProposal(uint256 ID) external returns(bool){
        require(_index[msg.sender] != 0);
        require(!_proposalVoted[msg.sender][ID]);
        _proposalVoted[msg.sender][ID] = true;
        
        uint256 votedFT;
        
        for(uint256 t = 1 ; t < 22; ++t){
            if(_proposalVoted[_node[t]][ID]){votedFT += _stakedFT[_node[t]];}
        }
        
        if(votedFT * 2 >= _totalStakedFT){
            _parallelContract[_main[ID]] = _parallel[ID]; //the Ethereum parallel contract of the BSC main contract
            _mainContractOfThat[_parallel[ID]] = _main[ID];
            
            createTokenRequest(address(0), _main[ID], _parallel[ID], _fee[ID], false);
            
            _signed[ID] = true;
            return true;
        }
        else{return false;}
    }
    
    function createTokenRequest(address owner, address main, address parallel, uint256 fee, bool full) internal returns (uint256){
        uint256 requests = _addTokenRequests;
        FT.transferFrom(msg.sender, address(this), fee);
        FT.burn(fee);
        _owner[requests] = owner;
        _addTokenMainContract[requests] = main;
        _addTokenParallelContract[requests] = parallel;
        _addTokenFee[requests] = fee;
        
        _parallelContract[main] = parallel;
        _mainContractOfThat[parallel] = main;
        _full[main] = full;
        
        ++_addTokenRequests;
        
        return requests;
    }
    
}