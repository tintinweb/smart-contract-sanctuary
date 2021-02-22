/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

pragma solidity >=0.4.21 <0.6.0;

contract CertInterface{
  function addrFromPKey(bytes memory pkey) public view returns(address);

  function pkeyFromAddr(address addr) public view returns(bytes memory);

  function is_pkey_exist(bytes memory pkey) public view returns(bool);
}

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

contract YZDataInterface{
  uint256 public price;
  address payable public bank_account;
  function is_program_hash_available(bytes32 program_hash) public view returns(bool) ;
  function get_cert_proxy() public view returns(address);
}


contract YZDataRequest {
  using SafeMath for uint256;
    struct YZRequest{
      address payable from;
      bytes pkey4v;
      bytes secret;
      bytes input;
      bytes32 program_hash;
      uint token_amount;
      uint gas_price;
      uint block_number;
      bool settled;
      bool exists;
    }
    mapping (bytes32 => YZRequest) request_infos;

    YZDataInterface data;
    CertInterface public cert_proxy;
    uint256 public total_deposit;

    constructor(address _data) public{
      data = YZDataInterface(_data);
      cert_proxy = CertInterface(data.get_cert_proxy());
      total_deposit = 0;
    }

    event RequestData(bytes32 request_hash);
    function request_data(bytes memory secret,
                          bytes memory input,
                          bytes32 program_hash, uint gas_price) public payable returns(bytes32 request_hash){

      //!Ignore the check for now
      bytes memory pkey = cert_proxy.pkeyFromAddr(msg.sender);
      require(pkey.length != 0, "not a registered user");
      request_hash = keccak256(abi.encode(msg.sender, pkey, secret, input, program_hash, gas_price));
      require(request_infos[request_hash].exists == false, "already exist");
      require(msg.value >= data.price(), "not enough budget");

      request_infos[request_hash].from = msg.sender;
      request_infos[request_hash].pkey4v = pkey;
      request_infos[request_hash].secret = secret;
      request_infos[request_hash].input = input;
      request_infos[request_hash].program_hash = program_hash;
      request_infos[request_hash].token_amount = msg.value;
      request_infos[request_hash].gas_price = gas_price;
      request_infos[request_hash].block_number = block.number;
      request_infos[request_hash].settled = false;
      request_infos[request_hash].exists = true;

      emit RequestData(request_hash);
      return request_hash;
    }

    event RefundRequest(bytes32 request_hash, uint256 old_amount, uint256 new_amount);
    function refund_request(bytes32 request_hash) public payable{
      require(request_infos[request_hash].exists, "request not exist");
      require(request_infos[request_hash].settled, "already settled");
      require(request_infos[request_hash].from == msg.sender, "only request owner can refund");

      uint256 old = request_infos[request_hash].token_amount;
      request_infos[request_hash].token_amount = request_infos[request_hash].token_amount.safeAdd(msg.value);

      total_deposit += msg.value;
      emit RefundRequest(request_hash, old, request_infos[request_hash].token_amount);
    }

    event SubmitResult(bytes32 request_hash, bytes data, uint cost_gas, bytes result, bytes sig, uint256 cost_token, uint256 return_token);
    event SResultInsufficientFund(bytes32 request_hash, uint256 expect_fund, uint256 actual_fund);
    function submit_result(bytes32 request_hash, bytes memory data_hash, uint cost, bytes memory result, bytes memory sig) public returns(bool){
      require(request_infos[request_hash].exists, "request not exist");
      require(request_infos[request_hash].settled, "already settled");

      YZRequest storage r = request_infos[request_hash];
      bytes32 vhash = keccak256(abi.encodePacked(request_hash, data_hash, cost, result));
      bool v = verify_signature(vhash, sig, r.pkey4v);
      require(v, "invalid data");

      uint amount = cost.safeMul(request_infos[request_hash].gas_price);
      amount = amount.safeAdd(data.price());

      //emit event instead of revert, so users can refund
      if(amount > request_infos[request_hash].token_amount){
        emit SResultInsufficientFund(request_hash, amount, request_infos[request_hash].token_amount);
        return false;
      }

      r.settled = true;
      uint rest = r.token_amount.safeSub(amount);
      total_deposit = total_deposit.safeSub(amount);
      data.bank_account().transfer(amount);
      if(rest > 0){
        total_deposit = total_deposit.safeSub(rest);
        r.from.transfer(rest);
      }
      emit SubmitResult(request_hash, data_hash, cost, result, sig, amount, rest);
    }

    event RevokeRequest(bytes32 request_hash);
    function revoke_request(bytes32 request_hash) public{
      YZRequest storage r = request_infos[request_hash];
      require(msg.sender == r.from, "not owner of this request");
      require(r.settled == false, "alread settled");

      //require(block.number - r.block_number >= revoke_period, "not long enough for revoke");

      //TODO: charge fee for revoke
      r.settled = true;
      total_deposit = total_deposit.safeSub(r.token_amount);
      r.from.transfer(r.token_amount);
      emit RevokeRequest(request_hash);
    }

    function verify_signature(bytes32 hash, bytes memory sig, bytes memory pkey) private pure returns (bool){
      bytes32  r = bytesToBytes32(slice(sig, 0, 32));
      bytes32  s = bytesToBytes32(slice(sig, 32, 32));
      byte v1 = slice(sig, 64, 1)[0];
      uint8 v = uint8(v1) + 27;
      address pub = ecrecover(hash, v, r, s);
      address expected = getAddressFromPublicKey(pkey);

      return pub == expected;
    }

    function slice(bytes memory _data, uint start, uint len) public pure returns (bytes memory){
      bytes memory b = new bytes(len);

      for(uint i = 0; i < len; i++){
        b[i] = _data[i + start];
      }

      return b;
    }

    function bytesToBytes32(bytes memory source) public pure returns (bytes32 result) {
      assembly {
        result := mload(add(source, 32))
      }
    }
    function getAddressFromPublicKey(bytes memory _publicKey) public pure returns (address signer) {
      bytes32 hash = keccak256(_publicKey);
      address wallet = address(uint160(bytes20(hash)));
      return wallet;
    }
}

contract YZDataRequestFactory{
  event NewYZDataRequest(address addr);
  function createYZDataRequest(address data) public returns(address){
    YZDataRequest r = new YZDataRequest(data);
    emit NewYZDataRequest(address(r));
    return address(r);
  }
}