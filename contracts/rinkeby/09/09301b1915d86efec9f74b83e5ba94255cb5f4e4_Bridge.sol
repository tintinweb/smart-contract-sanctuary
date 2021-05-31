/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IF{
    
    function transfer(uint256 maount, address token) external returns(bool);
    
}

interface IERC20{

  function transfer(address recipient, uint256 amount) external;
  
  function transferFrom(address sender, address recipient, uint256 amount) external;
  
  function mint(address to, uint256 amount) external;

  function burn(uint256 amount) external;  

}

contract Bridge{

    IERC20 FT;
    
    constructor (address FTcontract){
        FT = IERC20(FTcontract);
    }
    
    uint256 private _totalStakedFT = 0; //amount of FT staked on the smart contract
    uint256 private _nodeFT = 150000000000;//FT needed to start a node
    
    mapping (uint256 => address) private _node;
    
    //================================================================================================================================================================================    
    mapping (address => uint256) private _stakedFT; // address aka node, staked FT on a specififc network pair
    mapping (address => uint256) private _block; //block the node verified at
    mapping (address => uint256) private _index; //index of node on the bridge
    
    mapping (address => uint256) private _lockBlock; //block the nodes assets got locked at
    mapping (address => uint256) private _lockedFT; //locked FT
    //================================================================================================================================================================================
        
    //================================================================================================================================================================================
    uint256 private _sendOrdersCount = 0;
        
    mapping (uint256 /*orderID*/ => address) private _sendSender;
    mapping (uint256 /*orderID*/ => address) private _sendTokenAddressFrom;
    mapping (uint256 /*orderID*/ => uint256) private _sendAmount;
    mapping (uint256 /*orderID*/ => uint256) private _sendFee;
    //================================================================================================================================================================================  
    
    //================================================================================================================================================================================    
    uint256 private _receiveOrdersCount = 1;
    
    mapping (uint256 => bool) private _processed; //if this transcation went through or not yet
    
    mapping (uint256 /*orderID*/ => address) private _receiveSender;
    mapping (uint256 /*orderID*/ => address) private _receiveTokenAddressFrom;
    mapping (uint256 /*orderID*/ => uint256) private _receiveAmount;
    mapping (uint256 /*orderID*/ => uint256) private _receiveFee;
    
    mapping(uint256 => address) private _creator;
    mapping (address => mapping (uint256 => bool)) private _voted; //if a node voted or not on this order
    mapping (uint256 => uint256) private _votedFT;
    
    mapping (address /*sender*/ => mapping (uint256 /*amount*/ => mapping(uint256 /*fee*/ => mapping (uint256 /*index*/ => mapping (address /*token Address From*/ => bool /*created or not*/))))) private _receiveOrder;
    mapping (address /*sender*/ => mapping (uint256 /*amount*/ => mapping(uint256 /*fee*/ => mapping (uint256 /*index*/ => mapping (address /*token Address From*/ => uint256 /*Index*/))))) private _receiveOrderIndex;    
    //================================================================================================================================================================================
    
    //================================================================================================================================================================================ 
    uint256 private _proposalsCount = 0;    
    
    mapping (uint256 => address) private _proposalCreator;
    
    mapping (uint256 => address) private _ThisMain;
    mapping (uint256 => address) private _ThatParallel;
    
    mapping (uint256 => address) private _ThisParallel;
    mapping (uint256 => address) private _ThatMain;
    
    mapping (uint256 => bool) private _signed;
    
    mapping (uint256 /*proposalID*/ => uint256) private _proposalVotesCount; // number of votes this proposal received
    mapping (uint256 => address) private _proposalVotedNodes; //nodes that voted on this proposal
    mapping (address => mapping (uint256 => bool)) private _proposalVoted; //if a node voted or not on this proposal
        
    mapping (address /*ThisMain*/ => address /*ThatParallel*/ ) private _parallelContract; //the Ethereum parallel contract of the BSC main contract
    mapping (address /*ThisParallel*/ => address /*ThatMain*/ ) private _mainContract; //the Ethereum main contract of the BSC parallel contract */
    
    mapping (address /*ThatParallel*/ => address /*ThisMain*/) private _parallelContractOfThat; //The BSC main contract of that ETH parallel contract
    mapping (address /*ThatMain*/=> address /*ThisParallel*/) private _mainContractOfThat; //The BSC parallel contract of that ETH main contract
    
    function parallelContract(address thisMainContract) external view returns(address){
        return _parallelContract[thisMainContract];
    }
    function mainContract(address ThisParallelContract) external view returns(address){
        return _mainContract[ThisParallelContract];
    }
    //================================================================================================================================================================================    
    
    function bridge() external view returns (uint256 nodes, uint256 stakedFT, uint256 minFT){
        for(uint256 t = 1; t < 22; ++t){
            if(_node[t] != address(0)){++nodes;}
        }
        stakedFT = _totalStakedFT;
        minFT = _nodeFT;
    }
    function nodeStats(address node) external view returns(uint256 staked, uint256 verifiedBlock, uint256 locked, uint256 lockedFT, uint256 index) {
        staked = _stakedFT[node];
        verifiedBlock = _block[node];
        locked = _lockBlock[node];
        lockedFT = _lockedFT[node];
        index = _index[node];
    }
    function sendOrdersCount() external view returns(uint256 SendOrdersCount){
        SendOrdersCount = _sendOrdersCount;
    }
    function sendStats(uint256 ID) external view returns(address sender, uint256 amount, uint256 fee, address tokenAddressFrom){
        sender = _sendSender[ID];
        amount = _sendAmount[ID];
        fee = _sendFee[ID];
        tokenAddressFrom = _sendTokenAddressFrom[ID];
    }
    
    function depositStats(uint256 ID) external view returns(address sender, uint256 amount, uint256 fee, address tokenAddressFrom) {
        sender = _receiveSender[ID];
        tokenAddressFrom = _receiveTokenAddressFrom[ID];
        amount = _receiveAmount[ID];
        fee = _receiveFee[ID];
    }
    function depositProgress(uint256 ID) external view returns(uint256 votedFT, bool processed){
        votedFT = _votedFT[ID];
        processed = _processed[ID];
    }
    
    function receiveOrderIndex(address sender, uint256 amount, uint256 fee, uint256 index, address tokenAddressFrom) external view returns(uint256) {
        return _receiveOrderIndex[sender][amount][fee][index][tokenAddressFrom];
    }
    
    function orderProcess(address sender, uint256 amount, uint256 fee, uint256 index, address tokenAddressFrom) external view returns(bool){
        return _processed[_receiveOrderIndex[sender][amount][fee][index][tokenAddressFrom]];
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
        require(_stakedFT[msg.sender] + amount >= _nodeFT);
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
        require(_stakedFT[msg.sender] - amount >= _nodeFT || _stakedFT[msg.sender] - amount == 0);
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
    
    function transfer(uint256 amount, uint256 fee, address tokenAddressFrom) external {
        require(amount > 0);
        require(_parallelContract[tokenAddressFrom] != address(0) || _mainContract[tokenAddressFrom] != address(0) || tokenAddressFrom == address(0));
        
        if(tokenAddressFrom == address(0)){
            FT.transferFrom(msg.sender, address(this), fee + amount);
            FT.burn(amount+fee);
        }
        else{
            IERC20 token = IERC20(tokenAddressFrom);
            token.transferFrom(msg.sender, address(this), amount);
            FT.transferFrom(msg.sender, address(this), fee);
            if(_mainContract[tokenAddressFrom] != address(0)){token.burn(amount); FT.burn(fee);}
        }
        
        uint256 index = _sendOrdersCount;
        _sendSender[index] = msg.sender;
        _sendAmount[index] = amount;
        _sendFee[index] = fee;
        _sendTokenAddressFrom[index] = tokenAddressFrom;
        
        _sendOrdersCount += 1;
    }
    
    function deposit(address sender, uint256 amount, uint256 fee, uint256 index, address tokenAddressFrom) external {
        uint256 orderIndex = _receiveOrderIndex[sender][amount][fee][index][tokenAddressFrom];
        require(!_processed[orderIndex]);
        require(_parallelContract[tokenAddressFrom] != address(0) || _mainContract[tokenAddressFrom] != address(0) || tokenAddressFrom == address(0));
        
            _stakedFT[msg.sender] -= 1000000000;
            _totalStakedFT -= 1000000000;
            
        if(orderIndex == 0){
            
            uint256 ordersCount = _receiveOrdersCount;
            
            _receiveOrderIndex[sender][amount][fee][index][tokenAddressFrom] = ordersCount;
            
            _receiveSender[ordersCount] = sender;
            _receiveTokenAddressFrom[ordersCount] = tokenAddressFrom;
            _receiveAmount[ordersCount] = amount;
            _receiveFee[ordersCount] = fee;
            
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
            
            uint256 totalVoted;
            
            for(uint256 t=1; t<22; ++t){
                if(_voted[_node[t]][orderIndex]){
                    totalVoted += _stakedFT[_node[t]];
                }
            }
            
            if(totalVoted * 2 >= _totalStakedFT){
                uint256 claimedFees = fee * 10 / 100;
                uint256 claimedPunishmentFees;
                _stakedFT[_creator[orderIndex]] += claimedFees;
                
                for(uint256 t=1; t<22; ++t){
                    address node = _node[t];
                    if(_voted[node][orderIndex]){
                        uint256 reward = _stakedFT[node] * 80 / 100 / totalVoted;
                        claimedFees += reward;
                        if(_index[node] != 0){
                            _stakedFT[node] += reward + 1000000000;
                            claimedPunishmentFees += 1000000000;
                        }
                        else{
                            _lockedFT[node] += reward + 1000000000;
                        }
                    }
                }
                
                _stakedFT[msg.sender] += (fee - claimedFees);
                _totalStakedFT += fee + claimedPunishmentFees;
                
                if(tokenAddressFrom == address(0)){
                    FT.mint(sender, amount);
                }
                else if(_mainContractOfThat[tokenAddressFrom] != address(0)){ //sending from the parallel contract back to the main
                    IERC20 token = IERC20(tokenAddressFrom);
                    token.transfer(sender, amount);
                }
                else{ //sending from the main contract back to the parallel
                    IERC20 token = IERC20(tokenAddressFrom);
                    token.mint(sender, amount);
                }
                _processed[orderIndex] = true;
            }
        }

    }
    
    function sign(address sender, uint256 amount, uint256 fee, uint256 index, address tokenAddressFrom) external {
        uint256 orderIndex = _receiveOrderIndex[sender][amount][fee][index][tokenAddressFrom];
        require(!_processed[orderIndex]);
        
        if(_votedFT[orderIndex]*2 >= _totalStakedFT){
            
            uint256 totalVoted;
            
            for(uint256 t=1; t<22; ++t){
                if(_voted[_node[t]][orderIndex]){
                    totalVoted += _stakedFT[_node[t]];
                }
            }
            
            if(totalVoted >= _totalStakedFT){
                uint256 claimedFees = fee * 10 / 100;
                uint256 claimedPunishmentFees;
                _stakedFT[_creator[orderIndex]] += claimedFees;
                
                for(uint256 t=1; t<22; ++t){
                    address node = _node[t];
                    if(_voted[node][orderIndex]){
                        uint256 reward = _stakedFT[node] * 80 / 100 / totalVoted;
                        _stakedFT[node] += reward + 1000000000;
                        claimedFees += reward;
                        claimedPunishmentFees += 1000000000;
                    }
                }
                
                _stakedFT[msg.sender] += (fee - claimedFees);
                _totalStakedFT += fee + claimedPunishmentFees;
            }
        }
    }

    
    //================================================================================================================================================================================ 
    
    function proposalsCount() external view returns(uint256){
        return _proposalsCount;
    }
    function proposalInfo(uint256 ID) external view returns(address ThisMain, address ThatParallel, address ThatMain, address ThisParallel, uint256 votes, bool signed){
        ThisMain = _ThisMain[ID];
        ThatParallel = _ThatParallel[ID];
        ThatMain = _ThatMain[ID];
        ThisParallel =_ThisParallel[ID];
        votes = _proposalVotesCount[ID];
        signed = _signed[ID];
    }
    
    function createProposal(address ThisMain, address ThatParallel, address ThatMain, address ThisParallel) external returns(uint256) {
        uint256 proposalsCount = _proposalsCount;
        _proposalCreator[proposalsCount] = msg.sender;
        _ThisMain[proposalsCount] = ThisMain;
        _ThatParallel[proposalsCount] = ThatParallel;
        _ThatMain[proposalsCount] = ThatMain;
        _ThisParallel[proposalsCount] = ThisParallel;
        _proposalsCount += 1;
        return _proposalsCount-1;
    }
    function cancelProposal(uint256 proposalID) external returns(bool){
        require(msg.sender == _proposalCreator[proposalID]);
        _ThisMain[proposalID] = address(0);
        _ThatParallel[proposalID] = address(0);
        _ThatMain[proposalID] = address(0);
        _ThisParallel[proposalID] = address(0);
        return true;
    }
    function voteOnProposal(uint256 proposalID) external returns(bool){
        require(_index[msg.sender] != 0);
        require(!_proposalVoted[msg.sender][proposalID]);
        _proposalVoted[msg.sender][proposalID] = true;
        _proposalVotedNodes[_proposalVotesCount[proposalID]] = msg.sender;
        _proposalVotesCount[proposalID] += 1;
        return true;
    }
    function signProposal(uint256 proposalID) external returns(bool){
        require(!_signed[proposalID]);
        uint256 votedFT;
        uint256 votes = _proposalVotesCount[proposalID];
        
        for(uint256 t = 0 ; t < votes; ++t){
            votedFT += _stakedFT[_proposalVotedNodes[t]];
        }
        
        if(votedFT * 2 >= _totalStakedFT){
            _parallelContract[_ThisMain[proposalID]] = _ThatParallel[proposalID]; //the Ethereum parallel contract of the BSC main contract
            _mainContract[_ThisParallel[proposalID]] = _ThatMain[proposalID]; //the Ethereum main contract of the BSC parallel contract */
            _mainContractOfThat[_ThatParallel[proposalID]] = _ThisMain[proposalID]; //The BSC main contract of the ETH parallel contract
            _parallelContractOfThat[_ThatMain[proposalID]] = _ThisParallel[proposalID]; //The BSC parallel contract of the ETH main contract
            _signed[proposalID] = true;
            return true;
        }
        else{return false;}
    }
    
}