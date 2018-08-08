pragma solidity ^0.4.23;

contract UnionPay {
    event UserPay(address from,address to,uint256 amount, uint256 amountIndeed,uint256 transId);
    event BareUserPay(address from,uint256 amount,bytes data);  
    
    address public owner;  
    address public platform;
    mapping(bytes32 => uint8)  userReceipts;

    constructor() public {
      owner = msg.sender;
      platform = msg.sender;
    }
  
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
  
    function transferOwnership(address newOwner) public onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

    function safePay(uint256 _transId,uint256 _feePercentage,address _to, bytes _sig) payable public returns(bool) {
        require(_feePercentage>=0 && _feePercentage<=100);
        require(_to != address(0));
        require(userReceipts[getReceiptId(msg.sender,_to,_transId)] == 0);
        require(platform!=address(0));

        bytes32 message = prefixed(keccak256(msg.sender, _to, msg.value, _feePercentage,_transId));

        require(recoverSigner(message, _sig) == platform);
        userReceipts[getReceiptId(msg.sender,_to,_transId)] = 1;
        
        if (_feePercentage == 0){
            if (msg.value > 0){
                _to.transfer(msg.value);
            }
            emit UserPay(msg.sender,_to,msg.value,msg.value,_transId);
            return true;
        }        
        uint256 val = _feePercentage * msg.value;
        assert(val/_feePercentage == msg.value);
        val = val/100;
        if (msg.value>val){
            _to.transfer(msg.value - val);
        }
        emit UserPay(msg.sender,_to,msg.value,msg.value - val,_transId);
        return true;
    }
    
    function getReceiptId(address _from,address _to, uint256 _transId) internal pure returns(bytes32){
        return keccak256(_from, _to,_transId);
    }
    
    function receiptUsed(address _from,address _to,uint256 _transId) public view returns(bool){
        return userReceipts[getReceiptId(_from,_to,_transId)] == 1;
    }
    
    function plainPay() public payable returns(bool){
        emit BareUserPay(msg.sender,msg.value,msg.data);
        return true;
    }
    
    function () public payable{
        emit BareUserPay(msg.sender,msg.value,msg.data);
    }
    
    function setPlatform(address _checker) public onlyOwner{
        require(_checker!=address(0));
        platform = _checker;
    }
    
    function withdraw() public onlyOwner{
        require(platform!=address(0));
        platform.transfer(address(this).balance);
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }


    // Signature methods

    function splitSignature(bytes sig)
    internal
    pure
    returns(uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r: = mload(add(sig, 32))
            // second 32 bytes
            s: = mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v: = byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes sig)
    internal
    pure
    returns(address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns(bytes32) {
        return keccak256("\x19Ethereum Signed Message:\n32", hash);
    }
}