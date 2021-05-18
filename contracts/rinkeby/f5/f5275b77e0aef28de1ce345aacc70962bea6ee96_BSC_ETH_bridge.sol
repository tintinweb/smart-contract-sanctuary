/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

pragma solidity ^0.8.4;

interface IF{
    
    function transfer(uint256 maount, address token) external returns(bool);
    
}

interface IERC20{

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);
  
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  
  function mint(address to, uint256 amount) external;

  function burn(uint256 amount) external;  

}

//This smart contract is for the bridge that will handle transaction between BSC and ETH only
contract BSC_ETH_bridge{

    IERC20 FT;
    
    constructor (address FTcontract){
        FT = IERC20(FTcontract);
    }
    
    uint256 private _nodeCount = 0; //number of nodes linked to this BlockChain
    uint256 private _totalStakedFT = 0; //amount of FT staked on the smart contract
    uint256 private _nodeFT = 150000000000;//FT needed to start a node
    uint256 private _voteFT = 100000000000;//FT needed to vote
    
    uint256 _totalNodes;
    mapping (uint256 => address) private _nodes;
    
    //================================================================================================================================================================================    
    mapping (address => uint256) private _stakedFT; // address aka node, staked FT on a specififc network pair
    mapping (address => uint256) private _block; //block the node verified at
    
    mapping (address => uint256) private _lockBlock; //block the nodes assets got locked at
    mapping (address => uint256) private _lockedFT; //locked FT
    //================================================================================================================================================================================
        
    //================================================================================================================================================================================
    uint256 private _sendOrdersCount = 0;
        
    mapping (uint256 /*orderID*/ => address) private _sendSender;
    mapping (uint256 /*orderID*/ => address) private _sendTokenAddressFrom;
    mapping (uint256 /*orderID*/ => address) private _sendTokenAddressTo;
    mapping (uint256 /*orderID*/ => uint256) private _sendAmount;
    mapping (uint256 /*orderID*/ => uint256) private _sendFee;
    mapping (uint256 /*orderID*/ => uint256) private _sendSignFee; //fee payed to the node that signs the transaction
    mapping (uint256 /*orderID*/ => uint256) private _sendCreateFee; //Fee payed to the node that first creates the deposit
    //================================================================================================================================================================================  
    
    //================================================================================================================================================================================    
    uint256 private _receiveOrdersCount = 0;
    
    mapping (uint256 => bool) private _processed; //if this transcation went through or not yet
    
    mapping (uint256 /*orderID*/ => address) private _receiveSender;
    mapping (uint256 /*orderID*/ => address) private _receiveTokenAddressFrom;
    mapping (uint256 /*orderID*/ => address) private _receiveTokenAddressTo;
    mapping (uint256 /*orderID*/ => uint256) private _receiveAmount;
    mapping (uint256 /*orderID*/ => uint256) private _receiveFee;
    mapping (uint256 /*orderID*/ => uint256) private _receiveCreateFee;     
    mapping (uint256 /*orderID*/ => uint256) private _receiveSignFee;  
    
    mapping (uint256 /*orderID*/ => uint256) private _receiveBlock;//block the order was made at 
    
    mapping (uint256 /*orderID*/ => uint256) private _votesCount; // number of votes this order received
    mapping (uint256 => address) private _votedNodes; //nodes that voted on this order
    mapping (address => mapping (uint256 => bool)) private _voted; //if a node voted or not on this order
    
    mapping (address /*sender*/ => mapping (uint256 /*amount*/ => mapping(uint256 /*fee*/ => mapping(uint256 /*signFee*/ => mapping( /*createFee*/ uint256 => mapping (uint256 /*index*/ => mapping (address /*token Address From*/ => mapping(address /*token Address To*/ => bool /*created or not*/)))))))) private _receiveOrder;
    mapping (address /*sender*/ => mapping (uint256 /*amount*/ => mapping(uint256 /*fee*/ => mapping(uint256 /*signFee*/ => mapping( /*createFee*/ uint256 => mapping (uint256 /*index*/ => mapping (address /*token Address From*/ => mapping(address /*token Address To*/ => uint256 /*Index*/)))))))) private _receiveOrderIndex;    
    //================================================================================================================================================================================
    
    //================================================================================================================================================================================ 
    uint256 private _proposalsCount = 0;    
    
    mapping (uint256 => bool) private _proposalCreated;//if a proposal with this index was created
    mapping (uint256 => address) private _proposalCreator;
    
    mapping (uint256 => address) private _ThisMain;
    mapping (uint256 => address) private _ThatParallel;
    
    mapping (uint256 => address) private _ThisParallel;
    mapping (uint256 => address) private _ThatMain;
    
    mapping (uint256 /*proposalID*/ => uint256) private _proposalVotesCount; // number of votes this proposal received
    mapping (uint256 => address) private _proposalVotedNodes; //nodes that voted on this proposal
    mapping (address => mapping (uint256 => bool)) private _proposalVoted; //if a node voted or not on this proposal
        
    mapping (address /*ThisMain*/ => address /*ThatParallel*/ ) private _parallelContract; //the Ethereum parallel contract of the BSC main contract
    mapping (address /*ThisParallel*/ => address /*ThatMain*/ ) private _mainContract; //the Ethereum main contract of the BSC parallel contract */
    //================================================================================================================================================================================    
    
    function bridge() external view returns (uint256 nodes, uint256 stakedFT, uint256 minFT){
        nodes = _nodeCount;
        stakedFT = _totalStakedFT;
        minFT = _nodeFT;
    }
    function nodeStats(address node) external view returns(uint256 staked, uint256 verifiedBlock, uint256 locked, uint256 lockedFT) {
        staked = _stakedFT[node];
        verifiedBlock = _block[node];
        locked = _lockBlock[node];
        lockedFT = _lockedFT[node];
    }
    function sendOrdersCount() external view returns(uint256 SendOrdersCount){
        SendOrdersCount = _sendOrdersCount;
    }
    function depositStats(uint256 ID) external view returns(address sender, address tokenAddressFrom, address tokenAddressTo, uint256 amount, uint256 fee, uint256 createFee, uint256 signFee, uint256 votesCount, bool processed) {
        sender = _receiveSender[ID];
        tokenAddressFrom = _receiveTokenAddressFrom[ID];
        tokenAddressTo = _receiveTokenAddressTo[ID];
        amount = _receiveAmount[ID];
        fee = _receiveFee[ID];
        createFee = _sendCreateFee[ID];
        signFee = _receiveSignFee[ID];
        votesCount = _votesCount[ID];
        processed = _processed[ID];
    }
    function sendStats(uint256 ID) external view returns (address sender, address tokenFrom, address tokenTo, uint256 amount, uint256 fee, uint256 createFee, uint256 signFee) {
        sender = _sendSender[ID];
        tokenFrom = _sendTokenAddressFrom[ID];
        tokenTo = _sendTokenAddressTo[ID];
        amount = _sendAmount[ID];
        fee = _sendFee[ID];
        createFee = _sendCreateFee[ID];
        signFee = _sendSignFee[ID];
    }
    
    function receiveOrderIndex(address sender, uint256 amount, uint256 fee, uint256 createFee, uint256 signFee, uint256 index, address tokenAddressFrom, address tokenAddressTo) external view returns(uint256) {
        return _receiveOrderIndex[sender][amount][fee][signFee][createFee][index][tokenAddressFrom][tokenAddressTo];
    }
    
    function orderProcess(address sender, uint256 amount, uint256 fee, uint256 createFee, uint256 signFee, uint256 index, address tokenAddressFrom, address tokenAddressTo) external view returns(bool){
        return _processed[_receiveOrderIndex[sender][amount][fee][signFee][createFee][index][tokenAddressFrom][tokenAddressTo]];
    }
    
    //================================================================================================================================================================================ 
        
    function stake(uint256 amount) external returns(bool){
        require(_stakedFT[msg.sender] + amount >= _nodeFT);
        require(_lockBlock[msg.sender] == 0);
        FT.transferFrom(msg.sender, address(this), amount);
        _stakedFT[msg.sender] += amount;
        _block[msg.sender] = block.number;
        _totalStakedFT += amount;
        
        if(_stakedFT[msg.sender] == amount){
            _nodes[_totalNodes] = msg.sender;
            _totalNodes += 1;
            _nodeCount += 1;
        }
        return true;    
    }
    
    function unStake(uint256 amount) external returns(bool){
        require(_stakedFT[msg.sender] - amount >= _nodeFT || _stakedFT[msg.sender] - amount == 0);
        FT.transfer(msg.sender, amount);
        _totalStakedFT -= amount;
        if(_stakedFT[msg.sender] == 0){_nodeCount -= 1;}
        return true;
    }
    
    function verify() external {
        _block[msg.sender] = block.number;
    }

    function lock(address node) external returns(bool){
        require(_lockBlock[node] == 0);
        require(block.number - _block[node] >= 1200);
        uint256 staked = _stakedFT[node];
        _lockBlock[node] = block.number;
        _lockedFT[node] = staked;
        _stakedFT[node] = 0;
        _totalStakedFT -= staked;
        _nodeCount -= 1;
        return true;
    }
    function unlock() external returns(bool){
        require(block.number -_lockBlock[msg.sender] >= 201600);
        FT.transfer(msg.sender, _lockedFT[msg.sender]);
        _lockBlock[msg.sender] = 0;
        return true;
    }
    
    function signable(address sender, uint256 amount, uint256 fee, uint256 createFee, uint256 signFee, uint256 index, address tokenAddressFrom, address tokenAddressTo) external view returns(bool){
        uint256 orderIndex = _receiveOrderIndex[sender][amount][fee][signFee][createFee][index][tokenAddressFrom][tokenAddressTo];
        
        uint256 votedFT;
        uint256 votes = _votesCount[orderIndex];
        
        for(uint256 t = 0 ; t < votes; ++t){
            votedFT += _stakedFT[_votedNodes[t]];
        }
        
        if(votedFT *2 > _totalStakedFT){return true;}
        else{return false;}
    } 
    //================================================================================================================================================================================ 
    
    function transfer(uint256 amount, uint256 fee, uint256 createFee, uint256 signFee, address tokenAddressFrom, address tokenAddressTo) external returns(bool) {
        require(amount > 0);
        require(_parallelContract[tokenAddressFrom] == tokenAddressTo || _mainContract[tokenAddressFrom] == tokenAddressTo);
        IERC20 token = IERC20(tokenAddressFrom);
        
        require(token.transferFrom(msg.sender, address(this), amount));
        require(FT.transferFrom(msg.sender, address(this), fee + createFee + signFee));
        
        if(_mainContract[tokenAddressFrom] == tokenAddressTo){token.burn(amount);}
        
        uint256 index = _sendOrdersCount;
        _sendSender[index] = msg.sender;
        _sendTokenAddressFrom[index] = tokenAddressFrom;
        _sendTokenAddressTo[index] = tokenAddressTo;
        _sendAmount[index] = amount;
        _sendFee[index] = fee;
        _sendCreateFee[index] = createFee;
        _sendSignFee[index] = signFee;
        
        _sendOrdersCount += 1;
        
        return true;
    }
    
    function deposit(address sender, uint256 amount, uint256 fee, uint256 createFee, uint256 signFee, uint256 index, address tokenAddressFrom, address tokenAddressTo) external returns(bool) {
        require(_parallelContract[tokenAddressTo] == tokenAddressFrom || _mainContract[tokenAddressTo] == tokenAddressFrom);
        require(_stakedFT[msg.sender] >= _voteFT);     
        
        if(!_receiveOrder[sender][amount][fee][signFee][createFee][index][tokenAddressFrom][tokenAddressTo]){
            
           // _stakedFT[msg.sender] -= 1;
           // _totalStakedFT -= 1;
            _receiveOrder[sender][amount][fee][signFee][createFee][index][tokenAddressFrom][tokenAddressTo] = true;
            _receiveOrderIndex[sender][amount][fee][signFee][createFee][index][tokenAddressFrom][tokenAddressTo] = _receiveOrdersCount;
            
            _receiveSender[_receiveOrdersCount] = sender;
            _receiveTokenAddressFrom[_receiveOrdersCount] = tokenAddressFrom;
            _receiveTokenAddressTo[_receiveOrdersCount] = tokenAddressTo;
            _receiveAmount[_receiveOrdersCount] = amount;
            _receiveFee[_receiveOrdersCount] = fee;
            _receiveCreateFee[_receiveOrdersCount] = createFee;
            _receiveSignFee[_receiveOrdersCount] = signFee;
            
            _receiveBlock[_receiveOrdersCount] = block.number;
            
            _votedNodes[_votesCount[_receiveOrdersCount]] = msg.sender;
            _votesCount[_receiveOrdersCount] += 1;
            _voted[msg.sender][_receiveOrdersCount] = true;
            
            _receiveOrdersCount += 1; 
            
        }
        else{
            uint256 orderIndex = _receiveOrderIndex[sender][amount][fee][signFee][createFee][index][tokenAddressFrom][tokenAddressTo];
            require(!_processed[orderIndex]);
            require(!_voted[msg.sender][orderIndex]);
            
          //  _stakedFT[msg.sender] -= 1;
           // _totalStakedFT -=1;
            
            _votedNodes[_votesCount[orderIndex]] = msg.sender;
            _votesCount[orderIndex] += 1;
            _voted[msg.sender][orderIndex] = true;
        }

        return true;
    }
    
    function signDeposit(address sender, uint256 amount, uint256 fee, uint256 signFee, uint256 createFee, uint256 index, address tokenAddressFrom, address tokenAddressTo) external returns(bool) {
        uint256 orderIndex = _receiveOrderIndex[sender][amount][fee][signFee][createFee][index][tokenAddressFrom][tokenAddressTo];
        require(!_processed[orderIndex]);
        require(_stakedFT[msg.sender] >= _voteFT);
        
        uint256 votedFT;
        uint256 claimedrewards;
        //uint256 votes = _votesCount[orderIndex];
        
        for(uint256 t = 0 ; t < _votesCount[orderIndex]; ++t){
            votedFT += _stakedFT[_votedNodes[t]];
        }
        
        if(votedFT *2 > _totalStakedFT){
             uint256 validNodes;
            for(uint256 t = 0 ; t < _votesCount[orderIndex]; ++t){
            if(_stakedFT[_votedNodes[t]] > 0){
                uint256 reward = (_stakedFT[_votedNodes[t]] * fee) / votedFT;
                claimedrewards += reward;
                _stakedFT[_votedNodes[t]] += 1 + reward;
                validNodes += 1;
                
            }
            else{
                _lockedFT[_votedNodes[t]] += 1;}
                
            }     
            
            if(_stakedFT[_votedNodes[0]] > 0){_stakedFT[_votedNodes[0]] += createFee;}
            else{ _stakedFT[msg.sender] += createFee;}
            
            _stakedFT[msg.sender] += fee - claimedrewards;
            
            _totalStakedFT += validNodes + fee + createFee + signFee;
            
            _processed[orderIndex] = true;
            
            IERC20 token = IERC20(tokenAddressTo);
              
            if(_parallelContract[tokenAddressTo] != address(0)){token.transfer(sender, amount);}
            else{token.mint(sender, amount);}

            return true;
                
        }
        
        else{return false;}
        
    }
    
    //================================================================================================================================================================================ 
    
    function proposalsCount() external view returns(uint256){
        return _proposalsCount;
    }
    function proposalInfo(uint256 ID) external view returns(address ThisMain, address ThatParallel, address ThatMain, address ThisParallel, uint256 votes){
        ThisMain = _ThisMain[ID];
        ThatParallel = _ThatParallel[ID];
        ThatMain = _ThatMain[ID];
        ThisParallel =_ThisParallel[ID];
        votes = _proposalVotesCount[ID];
    }
    
    function createProposal(address ThisMain, address ThatParallel, address ThatMain, address ThisParallel) external returns(uint256) {
        _proposalCreated[_proposalsCount] = true;
        _proposalCreator[_proposalsCount] = msg.sender;
        _ThisMain[_proposalsCount] = ThisMain;
        _ThatParallel[_proposalsCount] = ThatParallel;
        _ThatMain[_proposalsCount] = ThatMain;
        _ThisParallel[_proposalsCount] = ThisParallel;
        _proposalsCount += 1;
        return _proposalsCount-1;
    }
    function cancelProposal(uint256 proposalID) external returns(bool){
        require(msg.sender == _proposalCreator[proposalID]);
        _proposalCreated[proposalID] = false;
        return true;
    }
    function voteOnProposal(uint256 proposalID) external returns(bool){
        require(_stakedFT[msg.sender] >= _voteFT);
        require(!_proposalVoted[msg.sender][proposalID]);
        _proposalVoted[msg.sender][proposalID] = true;
        _proposalVotedNodes[_proposalVotesCount[proposalID]] = msg.sender;
        _proposalVotesCount[proposalID] += 1;
        return true;
    }
    function signProposal(uint256 proposalID) external returns(bool){
        uint256 votedFT;
        uint256 votes = _proposalVotesCount[proposalID];
        
        for(uint256 t = 0 ; t < votes; ++t){
            votedFT += _stakedFT[_proposalVotedNodes[t]];
        }
        
        if(votes * 2 > _totalStakedFT){
            _parallelContract[_ThisMain[proposalID]] = _ThatParallel[proposalID]; //the Ethereum parallel contract of the BSC main contract
            _mainContract[_ThisParallel[proposalID]] = _ThatMain[proposalID]; //the Ethereum main contract of the BSC parallel contract */
            return true;
        }
        else{return false;}
    }
    
}