pragma solidity ^0.4.23;

contract ERC20Interface {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) public constant returns (uint256 balance);
}
contract MultiSigWallet{
    event Deposit(address _sender, uint256 _value);
    event Transacted(address _to, address _tokenContractAddress,uint256 value);
    mapping (address => bool) public isSigner;
    uint8 public required;
    uint256 public sequenceId;
    //创建合约

    constructor(address[] _signers, uint8 _required) public{
        require(_required <= _signers.length &&  _required > 0 && _signers.length > 0);
        for (uint8 i=0; i<_signers.length; i++)
            isSigner[_signers[i]] = true;
        required = _required;
        sequenceId =0;
    }
    //收款
    function()
        payable public{
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    //发起一笔eth多签交易
    function submitTransactionWithSignatures(address _destination, uint256 _value,  uint8[] _v, bytes32[] _r,bytes32[] _s) public{
        require(_destination != 0 && _destination!=address(this));

        bytes32 _msgHash = keccak256(&quot;ETHER&quot;, _destination, _value, sequenceId);
        verifySignatures(_msgHash, _v, _r,_s);
        _destination.transfer(_value);
        emit Transacted(_destination,0,_value);
        sequenceId =sequenceId +1;
    }

    //发起一笔token多签交易
    function submitTransactionWithSignaturesToken(address _destination,address _tokenContractAddress,uint256 _value, uint8[] _v, bytes32[] _r,bytes32[] _s) public{
        require(_destination != 0 &&_destination!=address(this));

        bytes32 _msgHash = keccak256(&quot;TOKEN&quot;, _destination, _value, sequenceId);
        verifySignatures(_msgHash, _v, _r,_s);
        ERC20Interface instance = ERC20Interface(_tokenContractAddress);
        require(instance.transfer(_destination,_value));
        emit Transacted(_destination,_tokenContractAddress,_value);
        sequenceId =sequenceId + 1;
      }

    function verifySignatures(bytes32 _msgHash, uint8[] _v, bytes32[] _r,bytes32[] _s) view private{
        uint8 hasConfirmed=0;
        for (uint8 i=0; i<_v.length; i++){
             require(isSigner[ecrecover(_msgHash, _v[i], _r[i], _s[i])]);
             hasConfirmed++;
        }
        require(hasConfirmed >= required);
    }

}