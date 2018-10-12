pragma solidity ^0.4.25;

contract ERC20 {
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
}

contract XEXHolder{
    address private holder1_;
    address private holder2_;
    address private holder3_;
    bool private holder1Reset_;
    bool private holder2Reset_;
    bool private holder3Reset_;
    bool private holder1Transaction_;
    bool private holder2Transaction_;
    bool private holder3Transaction_;

    address private token_;
    uint256 private transactionNonce_;
    address private transactionTo_;
    uint256 private transactionValue_;

    event HolderSetted(address indexed _address1,address indexed _address2,address indexed _address3);
    event HolderReseted(bool _vote);
    event TransactionStarted(address indexed _address,uint _value);
    event TransactionConfirmed(address indexed _address,bool _vote);
    event TransactionSubmitted(address indexed _address,uint _value);
    
    modifier onlyHolder() {
        require(isHolder(msg.sender));
        _;
    }
    
    constructor(address _token) public{
        token_=_token;
        holder1_=msg.sender;
        holder2_=address(0);
        holder3_=address(0);
        holder1Reset_=false;
        holder2Reset_=false;
        holder3Reset_=false;
        holder1Transaction_=false;
        holder2Transaction_=false;
        holder3Transaction_=false;
    }
    
    function isHolder(address _address) public view returns (bool) {
        if(_address==address(0)){
            return false;
        }
        return _address==holder1_ || _address==holder2_ || _address==holder3_;
    }
    
    function setHolder(address _address1,address _address2,address _address3) public onlyHolder{
        require(_address1!=address(0) && _address2!=address(0) && _address3!=address(0));
        require(_address1!=_address2 && _address1!=_address3 && _address2!=_address3);
        
        uint _vote=0;
        if(holder1_==address(0)||holder1Reset_){
            _vote++;
        }
        if(holder2_==address(0)||holder2Reset_){
            _vote++;
        }
        if(holder3_==address(0)||holder3Reset_){
            _vote++;
        }
        require(_vote>=2);
        
        holder1_=_address1;
        holder2_=_address2;
        holder3_=_address3;
        holder1Reset_=false;
        holder2Reset_=false;
        holder3Reset_=false;
        clearTransaction();
        
        emit HolderSetted(holder1_,holder2_,holder3_);
    }
    
    function resetHolder(bool _vote) public onlyHolder{
        if(msg.sender==holder1_){
            holder1Reset_=_vote;
        }
        if(msg.sender==holder2_){
            holder2Reset_=_vote;
        }
        if(msg.sender==holder3_){
            holder3Reset_=_vote;
        }
        emit HolderReseted(_vote);
    }
    
    function startTransaction(address _address, uint256 _value) public onlyHolder{
        require(_address != address(0) && _value > 0);

        transactionNonce_ = uint256(keccak256(abi.encodePacked(block.difficulty,now)));
        transactionTo_ = _address;
        transactionValue_ = _value;
        emit TransactionStarted(_address,_value);

        confirmTransaction(transactionNonce_, true);
    }
    
    function showTransaction() public onlyHolder view returns(address _address, uint256 _value,uint256 _nonce){
        return (transactionTo_,transactionValue_,transactionNonce_);
    }

    function confirmTransaction(uint256 _nonce, bool _vote) public onlyHolder{
        require(transactionNonce_==_nonce);
        
        if(msg.sender==holder1_){
            holder1Transaction_=_vote;
        }
        if(msg.sender==holder2_){
            holder2Transaction_=_vote;
        }
        if(msg.sender==holder3_){
            holder3Transaction_=_vote;
        }
        emit TransactionConfirmed(msg.sender,_vote);
    }

    function submitTransaction() public onlyHolder{
        require(transactionTo_ != address(0) && transactionValue_ > 0);
        require(holder1Transaction_ && holder2Transaction_ && holder3Transaction_);
        require(!holder1Reset_ && !holder2Reset_ && !holder3Reset_);
        
        ERC20 _token = ERC20(token_);
        _token.approve(this, transactionValue_);
        _token.transferFrom(this,transactionTo_,transactionValue_);
        
        emit TransactionSubmitted(transactionTo_,transactionValue_);
        
        clearTransaction();
    }
    
    function clearTransaction() internal{
        transactionNonce_=0;
        transactionTo_=address(0);
        transactionValue_=0;
    }
}