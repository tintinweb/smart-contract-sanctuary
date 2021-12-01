pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Strings.sol";
import "./Validator.sol";

interface GenArt721CoreV2 {
  function isWhitelisted(address sender) external view returns (bool);
  function projectIdToCurrencySymbol(uint256 _projectId) external view returns (string memory);
  function projectIdToCurrencyAddress(uint256 _projectId) external view returns (address);
  function projectIdToArtistAddress(uint256 _projectId) external view returns (address payable);
  function projectIdToPricePerTokenInWei(uint256 _projectId) external view returns (uint256);
  function projectIdToAdditionalPayee(uint256 _projectId) external view returns (address payable);
  function projectIdToAdditionalPayeePercentage(uint256 _projectId) external view returns (uint256);
  function projectTokenInfo(uint256 _projectId) external view returns (address, uint256, uint256, uint256, bool, address, uint256, string memory, address);
  function renderProviderAddress() external view returns (address payable);
  function renderProviderPercentage() external view returns (uint256);
  function mint(address _to, uint256 _projectId, address _by) external returns (uint256 tokenId);
}

interface ERC20 {
  function balanceOf(address _owner) external view returns (uint balance);
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint remaining);
}

interface BonusContract {
  function triggerBonus(address _to) external returns (bool);
  function bonusIsActive() external view returns (bool);
}

contract GenArt721Minter_Flutter {
  using SafeMath for uint256;

  GenArt721CoreV2 public genArtCoreContract;

  uint256 constant ONE_MILLION = 1_000_000;

  address payable public ownerAddress;
  uint256 public ownerPercentage;

  mapping(uint256 => bool) public projectIdToBonus;
  mapping(uint256 => address) public projectIdToBonusContractAddress;
  mapping(uint256 => bool) public contractFilterProject;
  mapping(address => mapping (uint256 => uint256)) public projectMintCounter;
  mapping(uint256 => uint256) public projectMintLimit;
  mapping(uint256 => bool) public projectMaxHasBeenInvoked;
  mapping(uint256 => uint256) public projectMaxInvocations;
  mapping(uint256 => address) public validatorContracts;

  constructor(address _genArt721Address) public {
    genArtCoreContract=GenArt721CoreV2(_genArt721Address);
  }

  function setValidator(uint256 _projectId, address _validatorContract) public {
    require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
    validatorContracts[_projectId] = _validatorContract;
  }
  
  function getYourBalanceOfProjectERC20(uint256 _projectId) public view returns (uint256){
    uint256 balance = ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).balanceOf(msg.sender);
    return balance;
  }

  function checkYourAllowanceOfProjectERC20(uint256 _projectId) public view returns (uint256){
    uint256 remaining = ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).allowance(msg.sender, address(this));
    return remaining;
  }

  function setProjectMintLimit(uint256 _projectId,uint8 _limit) public {
    require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
    projectMintLimit[_projectId] = _limit;
  }

  function setProjectMaxInvocations(uint256 _projectId) public {
    require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
    uint256 maxInvocations;
    ( , , , maxInvocations, , , , , ) = genArtCoreContract.projectTokenInfo(_projectId);
    projectMaxInvocations[_projectId] = maxInvocations;
  }

  function setOwnerAddress(address payable _ownerAddress) public {
    require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
    ownerAddress = _ownerAddress;
  }

  function setOwnerPercentage(uint256 _ownerPercentage) public {
    require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
    ownerPercentage = _ownerPercentage;
  }

  function toggleContractFilter(uint256 _projectId) public {
    require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
    contractFilterProject[_projectId]=!contractFilterProject[_projectId];
  }

  function artistToggleBonus(uint256 _projectId) public {
    require(msg.sender==genArtCoreContract.projectIdToArtistAddress(_projectId), "can only be set by artist");
    projectIdToBonus[_projectId]=!projectIdToBonus[_projectId];
  }

  function artistSetBonusContractAddress(uint256 _projectId, address _bonusContractAddress) public {
    require(msg.sender==genArtCoreContract.projectIdToArtistAddress(_projectId), "can only be set by artist");
    projectIdToBonusContractAddress[_projectId]=_bonusContractAddress;
  }
  
  function addressCanMint(address _to, uint256 _projectId) public view returns (bool) {
    address validatorAddress = validatorContracts[_projectId];
    
    return validatorAddress == address(0) || Validator(validatorAddress).validateMint(_to);
  }
  
  function getValidationErrorMessage(uint256 _projectId) public view returns (string memory) {
    address validatorAddress = validatorContracts[_projectId];
    if (validatorAddress != address(0)) {
      Validator(validatorAddress).errorMessage();
    }
  }
  
  function mintDao(address _to, uint256 _projectId, uint256 count) public {
    require(genArtCoreContract.isWhitelisted(msg.sender), "can only be called by admin");
    require(!projectMaxHasBeenInvoked[_projectId], "Maximum number of invocations reached");

    for (uint256 x = 0; x < count; x++) {
      genArtCoreContract.mint(_to, _projectId, msg.sender);
    }
  }

  function purchase(uint256 _projectId) public payable returns (uint256 _tokenId) {
    return purchaseTo(msg.sender, _projectId);
  }

  // Remove `public`` and `payable`` to prevent public use
  // of the `purchaseTo`` function.
  function purchaseTo(address _to, uint256 _projectId) public payable returns(uint256 _tokenId){
    require(!projectMaxHasBeenInvoked[_projectId], "Maximum number of invocations reached");
    require(addressCanMint(_to, _projectId), getValidationErrorMessage(_projectId));
    
    if (keccak256(abi.encodePacked(genArtCoreContract.projectIdToCurrencySymbol(_projectId))) != keccak256(abi.encodePacked("ETH"))){
      require(msg.value==0, "this project accepts a different currency and cannot accept ETH");
      require(ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).allowance(msg.sender, address(this)) >= genArtCoreContract.projectIdToPricePerTokenInWei(_projectId), "Insufficient Funds Approved for TX");
      require(ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).balanceOf(msg.sender) >= genArtCoreContract.projectIdToPricePerTokenInWei(_projectId), "Insufficient balance.");
      _splitFundsERC20(_projectId);
    } else {
      require(msg.value>=genArtCoreContract.projectIdToPricePerTokenInWei(_projectId), "Must send minimum value to mint!");
      _splitFundsETH(_projectId);
    }

    // if contract filter is active prevent calls from another contract
    if (contractFilterProject[_projectId]) require(msg.sender == tx.origin, "No Contract Buys");

    // limit mints per address by project
    if (projectMintLimit[_projectId] > 0) {
        require(projectMintCounter[msg.sender][_projectId] < projectMintLimit[_projectId], "Reached minting limit");
        projectMintCounter[msg.sender][_projectId]++;
    }

    uint256 tokenId = genArtCoreContract.mint(_to, _projectId, msg.sender);

    // What if this overflows, since default value of uint256 is 0?
    // That is intended, so that by default the minter allows infinite
    // transactions, allowing the `genArtCoreContract` to stop minting
    // `uint256 tokenInvocation = tokenId % ONE_MILLION;`
    if (tokenId % ONE_MILLION == projectMaxInvocations[_projectId]-1){
        projectMaxHasBeenInvoked[_projectId] = true;
    }

    if (projectIdToBonus[_projectId]){
      require(BonusContract(projectIdToBonusContractAddress[_projectId]).bonusIsActive(), "bonus must be active");
      BonusContract(projectIdToBonusContractAddress[_projectId]).triggerBonus(msg.sender);
    }

    return tokenId;
  }

  function _splitFundsETH(uint256 _projectId) internal {
    if (msg.value > 0) {
      uint256 pricePerTokenInWei = genArtCoreContract.projectIdToPricePerTokenInWei(_projectId);
      uint256 refund = msg.value.sub(genArtCoreContract.projectIdToPricePerTokenInWei(_projectId));
      if (refund > 0) {
        msg.sender.transfer(refund);
      }
      uint256 renderProviderAmount = pricePerTokenInWei.div(100).mul(genArtCoreContract.renderProviderPercentage());
      if (renderProviderAmount > 0) {
        genArtCoreContract.renderProviderAddress().transfer(renderProviderAmount);
      }

      uint256 remainingFunds = pricePerTokenInWei.sub(renderProviderAmount);

      uint256 ownerFunds = remainingFunds.div(100).mul(ownerPercentage);
      if (ownerFunds > 0) {
        ownerAddress.transfer(ownerFunds);
      }

      uint256 projectFunds = pricePerTokenInWei.sub(renderProviderAmount).sub(ownerFunds);
      uint256 additionalPayeeAmount;
      if (genArtCoreContract.projectIdToAdditionalPayeePercentage(_projectId) > 0) {
        additionalPayeeAmount = projectFunds.div(100).mul(genArtCoreContract.projectIdToAdditionalPayeePercentage(_projectId));
        if (additionalPayeeAmount > 0) {
          genArtCoreContract.projectIdToAdditionalPayee(_projectId).transfer(additionalPayeeAmount);
        }
      }
      uint256 creatorFunds = projectFunds.sub(additionalPayeeAmount);
      if (creatorFunds > 0) {
        genArtCoreContract.projectIdToArtistAddress(_projectId).transfer(creatorFunds);
      }
    }
  }

  function _splitFundsERC20(uint256 _projectId) internal {
      uint256 pricePerTokenInWei = genArtCoreContract.projectIdToPricePerTokenInWei(_projectId);
      uint256 renderProviderAmount = pricePerTokenInWei.div(100).mul(genArtCoreContract.renderProviderPercentage());
      if (renderProviderAmount > 0) {
        ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).transferFrom(msg.sender, genArtCoreContract.renderProviderAddress(), renderProviderAmount);
      }
      uint256 remainingFunds = pricePerTokenInWei.sub(renderProviderAmount);

      uint256 ownerFunds = remainingFunds.div(100).mul(ownerPercentage);
      if (ownerFunds > 0) {
        ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).transferFrom(msg.sender, ownerAddress, ownerFunds);
      }

      uint256 projectFunds = pricePerTokenInWei.sub(renderProviderAmount).sub(ownerFunds);
      uint256 additionalPayeeAmount;
      if (genArtCoreContract.projectIdToAdditionalPayeePercentage(_projectId) > 0) {
        additionalPayeeAmount = projectFunds.div(100).mul(genArtCoreContract.projectIdToAdditionalPayeePercentage(_projectId));
        if (additionalPayeeAmount > 0) {
          ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).transferFrom(msg.sender, genArtCoreContract.projectIdToAdditionalPayee(_projectId), additionalPayeeAmount);
        }
      }
      uint256 creatorFunds = projectFunds.sub(additionalPayeeAmount);
      if (creatorFunds > 0) {
        ERC20(genArtCoreContract.projectIdToCurrencyAddress(_projectId)).transferFrom(msg.sender, genArtCoreContract.projectIdToArtistAddress(_projectId), creatorFunds);
      }
    }
}