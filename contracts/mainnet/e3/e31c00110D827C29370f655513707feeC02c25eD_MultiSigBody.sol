/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// File: contracts/MultiSigInterface.sol

pragma solidity >=0.4.21 <0.6.0;

contract MultiSigInterface{
  function update_and_check_reach_majority(uint64 id, string memory name, bytes32 hash, address sender) public returns (bool);
  function is_signer(address addr) public view returns(bool);
}

// File: contracts/MultiSigToolsWithReward.sol

pragma solidity >=0.4.21 <0.6.0;


contract RewardInterface{
  function reward(address payable to, uint256 amount) public;
}

//We do not inherit from MultiSigTools
contract MultiSigToolsWithReward{
  MultiSigInterface public multisig_contract;
  RewardInterface public reward_contract;

  constructor(address _contract, address _rewarder) public{
    require(_contract!= address(0x0));
    reward_contract = RewardInterface(_rewarder);

    multisig_contract = MultiSigInterface(_contract);
  }

  modifier only_signer{
    require(multisig_contract.is_signer(msg.sender), "only a signer can call in MultiSigTools");
    _;
  }

  modifier is_majority_sig(uint64 id, string memory name) {
    uint256 gas_start = gasleft();
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(multisig_contract.update_and_check_reach_majority(id, name, hash, msg.sender)){
      _;
    }
    uint256 gasused = (gas_start - gasleft()) * tx.gasprice;
    if(reward_contract != RewardInterface(0x0)){
      reward_contract.reward(tx.origin, gasused);
    }
  }

  modifier is_majority_sig_with_hash(uint64 id, string memory name, bytes32 hash) {
    uint256 gas_start = gasleft();
    if(multisig_contract.update_and_check_reach_majority(id, name, hash, msg.sender)){
      _;
    }
    uint256 gasused = (gas_start - gasleft()) * tx.gasprice;
    if(reward_contract != RewardInterface(0x0)){
      reward_contract.reward(tx.origin, gasused);
    }
  }

  event ChangeRewarder(address _old, address _new);
  function changeRewarder(uint64 id, address _rewarder) public only_signer
  is_majority_sig(id, "changeRewarder"){
    address old = address(reward_contract);
    reward_contract = RewardInterface(_rewarder);
    emit ChangeRewarder(old, _rewarder);
  }

  event TransferMultiSig(address _old, address _new);
  function transfer_multisig(uint64 id, address _contract) public only_signer
  is_majority_sig(id, "transfer_multisig"){
    require(_contract != address(0x0));
    address old = address(multisig_contract);
    multisig_contract = MultiSigInterface(_contract);
    emit TransferMultiSig(old, _contract);
  }
}

// File: contracts/erc20/IERC20.sol

pragma solidity >=0.4.21 <0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/utils/TokenClaimer.sol

pragma solidity >=0.4.21 <0.6.0;


contract TokenClaimer{

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);
    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
  function _claimStdTokens(address _token, address payable to) internal {
        if (_token == address(0x0)) {
            to.transfer(address(this).balance);
            return;
        }
        uint balance = IERC20(_token).balanceOf(address(this));

        (bool status,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(status, "call failed");
        emit ClaimedTokens(_token, to, balance);
  }
}

// File: contracts/MultiSigBody.sol

pragma solidity >=0.4.21 <0.6.0;



contract MultiSigBody is MultiSigToolsWithReward, TokenClaimer{

  constructor(address _multisig, address _reward) MultiSigToolsWithReward(_multisig, _reward) public{}

  function call_contract(uint64 id, address _addr, bytes memory _data, uint256 _value)
    public only_signer is_majority_sig(id, "call_contract"){
    (bool success,) = _addr.call.value(_value)(_data);
    require(success, "MultisigBody call failed");
  }

  function claimStdTokens(uint64 id, address _token, address payable to)
  public only_signer is_majority_sig(id, "claimStdTokens"){
    _claimStdTokens(_token, to);
  }

  event RecvETH(uint256 v);
  function() external payable{
    emit RecvETH(msg.value);
  }
}

contract MultiSigBodyFactory{

  event NewMultiSigBody(address addr, address _multisig);
  function createMultiSig(address _multisig, address _reward) public returns(address){
    MultiSigBody ms = new MultiSigBody(_multisig, _reward);
    emit NewMultiSigBody(address(ms), _multisig);
    return address(ms);
  }
}