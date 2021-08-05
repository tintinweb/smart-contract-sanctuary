/**
 *Submitted for verification at Etherscan.io on 2021-01-25
*/

// SPDX-License-Identifier: UNLICENSED

// File contracts/lib/IERC20.sol
pragma solidity 0.7.3;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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


// File contracts/lib/Ownable.sol
pragma solidity 0.7.3;
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/lib/DelegationProxy.sol
pragma solidity 0.7.3;

interface StakingNFT {
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function approve(address to, uint256 tokenId) external;
  function getApproved(uint256 tokenId) external view returns (address operator);
  function setApprovalForAll(address operator, bool _approved) external;
  function isApprovedForAll(address owner, address operator) external view returns (bool);
  function transferFrom(address from, address to, uint256 tokenId) external;
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}

interface ValidatorShare {
  function buyVoucher(uint256, uint256) external;
  function withdrawRewards() external;
  function sellVoucher(uint256, uint256) external;
  function unstakeClaimTokens() external;
  function getLiquidRewards(address user) external view returns (uint256);
}

interface ValidatorShare_New {
  function buyVoucher(uint256, uint256) external returns(uint256);
  function withdrawRewards() external;
  function sellVoucher(uint256, uint256) external;
  function unstakeClaimTokens() external;
  function sellVoucher_new(uint256, uint256) external;
  function unstakeClaimTokens_new(uint256) external;
}

interface IStakeManager {
  function getValidatorContract(uint256 validatorId) external view returns (address);
  function token() external view returns (IERC20);
  function NFTContract() external view returns (StakingNFT);
}

contract DelegationProxy is Ownable {
  uint256[] public validatorsList;
  mapping(uint256 => bool) public validatorsLookup;

  IStakeManager public stakeManager;

  constructor(IStakeManager _stakeManager) {
    require(_stakeManager != IStakeManager(0x0));

    stakeManager = _stakeManager;
  }

  function getLiquidRewards(uint256 validatorId) public view returns(uint256) {
    ValidatorShare delegationContract = ValidatorShare(stakeManager.getValidatorContract(validatorId));
    require(delegationContract != ValidatorShare(0x0));

    return delegationContract.getLiquidRewards(address(this));
  }

  function withdrawTokens(address tokenAddress, uint256 amount) public onlyOwner {
    IERC20(tokenAddress).transfer(owner(), amount);
  }

  function delegate(uint256[] memory validators, uint256[] memory amount, uint256 totalAmount) public onlyOwner {
    require(validators.length == amount.length);
    
    IERC20 token = stakeManager.token();
    token.approve(address(stakeManager), totalAmount);
    
    for (uint256 i = 0; i < validators.length; ++i) {
      uint256 validatorId = validators[i];

      if (!validatorsLookup[validatorId]) {
        validatorsLookup[validatorId] = true;
        validatorsList.push(validatorId);
      }

      ValidatorShare delegationContract = ValidatorShare(stakeManager.getValidatorContract(validatorId));
      require(delegationContract != ValidatorShare(0x0));

      // buy voucher
      delegationContract.buyVoucher(amount[i], 0);
    }
  }

  function delegate_new(uint256[] memory validators, uint256[] memory amount, uint256 totalAmount) public onlyOwner {
    require(validators.length == amount.length);
    
    IERC20 token = stakeManager.token();
    token.approve(address(stakeManager), totalAmount);
    
    for (uint256 i = 0; i < validators.length; ++i) {
      uint256 validatorId = validators[i];

      if (!validatorsLookup[validatorId]) {
        validatorsLookup[validatorId] = true;
        validatorsList.push(validatorId);
      }

      ValidatorShare_New delegationContract = ValidatorShare_New(stakeManager.getValidatorContract(validatorId));
      require(delegationContract != ValidatorShare_New(0x0));

      // buy voucher
      delegationContract.buyVoucher(amount[i], 0);
    }
  }

  function transferRewards(uint256[] memory validators) public onlyOwner {
    IERC20 token = stakeManager.token();
    StakingNFT nft = stakeManager.NFTContract();

    uint256 tokenBalanceBefore = token.balanceOf(address(this));

    for (uint256 i = 0; i < validators.length; ++i) {
      uint256 validatorId = validators[i];
      
      ValidatorShare delegationContract = ValidatorShare(stakeManager.getValidatorContract(validatorId));
      require(delegationContract != ValidatorShare(0x0));

      delegationContract.withdrawRewards();

      uint256 rewards = token.balanceOf(address(this)) - tokenBalanceBefore;
      token.transfer(nft.ownerOf(validatorId), rewards);
    }
  }

  function collectRewards(uint256[] memory validators) public onlyOwner {
    for (uint256 i = 0; i < validators.length; ++i) {
      uint256 validatorId = validators[i];
      
      ValidatorShare delegationContract = ValidatorShare(stakeManager.getValidatorContract(validatorId));
      require(delegationContract != ValidatorShare(0x0));

      delegationContract.withdrawRewards();
    }
  }

  function sellVoucher(uint256 validatorId, uint256 claimAmount, uint256 maximumSharesToBurn) public onlyOwner {
    ValidatorShare delegationContract = ValidatorShare(stakeManager.getValidatorContract(validatorId));
    require(delegationContract != ValidatorShare(0x0));

    delegationContract.sellVoucher(claimAmount, maximumSharesToBurn);
  }

  function sellVoucher_new(uint256 validatorId, uint256 claimAmount, uint256 maximumSharesToBurn) public onlyOwner {
    ValidatorShare_New delegationContract = ValidatorShare_New(stakeManager.getValidatorContract(validatorId));
    require(delegationContract != ValidatorShare_New(0x0));

    delegationContract.sellVoucher_new(claimAmount, maximumSharesToBurn);
  }

  function unstakeClaimTokens(uint256 validatorId) public onlyOwner {
    ValidatorShare delegationContract = ValidatorShare(stakeManager.getValidatorContract(validatorId));
    require(delegationContract != ValidatorShare(0x0));

    delegationContract.unstakeClaimTokens();
  }

  function unstakeClaimTokens_new(uint256 validatorId, uint256 unbondNonce) public onlyOwner {
    ValidatorShare_New delegationContract = ValidatorShare_New(stakeManager.getValidatorContract(validatorId));
    require(delegationContract != ValidatorShare_New(0x0));

    delegationContract.unstakeClaimTokens_new(unbondNonce);
  }

  function callAny(address target, bytes memory data) public onlyOwner {
    (bool success, ) = target.call(data); /* bytes memory returnData */
    require(success, "Call failed");
  }
}