// SPDX-License-Identifier: MIT
/// @dev size: 2.622 Kbytes
pragma solidity ^0.8.0;

import "./LossProvisionInterface.sol";
import "../security/Ownable.sol";
import "../Controller/ControllerInterface.sol";
import { IERC20 } from "../ERC20/IERC20.sol";

contract LossProvisionPool is LossProvisionInterface, Ownable {

    ControllerInterface public controller;

    uint256 public lossProvisionFee = 1e16;
    uint256 public buyBackProvisionFee = 1.5e16;

    event FeesChanged(uint256 indexed lossProvisionFee, uint256 indexed buyBackProvisionFee);

    constructor(ControllerInterface _controller) {
        controller = _controller;
    }

    /**
     * @dev See {LossProvisionInterface-getFeesPercent}.
     */
    function getFeesPercent() external override view returns (uint256) {
        return lossProvisionFee + buyBackProvisionFee;
    }

    function balanceOf(address stableCoin) public view returns (uint256) {
        require(controller.containsStableCoin(stableCoin), "StableCoin not supported");
        return IERC20(stableCoin).balanceOf(address(this));
    }

    function balanceOfAMPT() public view returns (uint256) {
        IERC20 amptToken = controller.amptToken();
        return amptToken.balanceOf(address(this));
    }

    function transfer(address stableCoin, address to) external onlyOwner {
        require(controller.containsStableCoin(stableCoin), "StableCoin not supported");
        assert(IERC20(stableCoin).transfer(to, balanceOf(stableCoin)));
    }

    function transferAMPT(address to) external onlyOwner {
        IERC20 amptToken = controller.amptToken();
        assert(amptToken.transfer(to, amptToken.balanceOf(address(this))));
    }

    function updateFees(uint256 _lossProvisionFee, uint256 _buyBackProvisionFee) external onlyOwner {
        lossProvisionFee = _lossProvisionFee;
        buyBackProvisionFee = _buyBackProvisionFee;

        emit FeesChanged(lossProvisionFee, buyBackProvisionFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract LossProvisionInterface {
    bool public isLossProvision = true;

    /**
     * @notice Calculates the percentage of the loan's principal that is paid as fee: `(lossProvisionFee + buyBackProvisionFee)`
     * @return The total fees percentage as a mantissa between [0, 1e18]
     */
    function getFeesPercent() external virtual view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {

    /// @notice owner address set on construction
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Transfers ownership role
     * @notice Changes the owner of this contract to a new address
     * @dev Only owner
     * @param _newOwner beneficiary to vest remaining tokens to
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must be non-zero");
        
        address currentOwner = owner;
        require(_newOwner != currentOwner, "New owner cannot be the current owner");

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../InterestRate/InterestRateModel.sol";
import "../Asset/AssetInterface.sol";
import "../LossProvisionPool/LossProvisionInterface.sol";
import { IERC20 } from "../ERC20/IERC20.sol";

abstract contract ControllerInterface {
    // Policy hooks
    function lendAllowed(address pool, address lender, uint256 amount) external virtual returns (uint256);
    function redeemAllowed(address pool, address redeemer, uint256 tokens) external virtual returns (uint256);
    function borrowAllowed(address pool, address borrower, uint256 amount) external virtual returns (uint256);
    function repayAllowed(address pool, address payer, address borrower, uint256 amount) external virtual returns (uint256);
    function createCreditLineAllowed(address pool, address borrower, uint256 collateralAsset) external virtual returns (uint256, uint256, uint256, uint256, uint256);


    function provisionPool() external virtual view returns (LossProvisionInterface);
    function interestRateModel() external virtual view returns (InterestRateModel);
    function assetsFactory() external virtual view returns (AssetInterface);
    function amptToken() external virtual view returns (IERC20);
    
    function containsStableCoin(address _stableCoin) external virtual view returns (bool);
    function getStableCoins() external virtual view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Base {
    function balanceOf(address owner) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
}

interface IERC20 is IERC20Base {
    function totalSupply() external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  * @title InterestRateModel Interface
  * @author Amplify
  */
abstract contract InterestRateModel {
	bool public isInterestRateModel = true;

    struct GracePeriod {
        uint256 fee;
        uint256 start;
        uint256 end;
    }

    /**
     * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows)`
     * @param cash The amount of cash in the pool
     * @param borrows The amount of borrows in the pool
     * @return The utilization rate as a mantissa between [0, 1e18]
     */
    function utilizationRate(uint256 cash, uint256 borrows) external virtual pure returns (uint256);

    /**
     * @notice Calculates the borrow rate for a given interest rate and GracePeriod length
     * @param interestRate The interest rate as a percentage number between [0, 100]
     * @return The borrow rate as a mantissa between  [0, 1e18]
     */
    function getBorrowRate(uint256 interestRate) external virtual view returns (uint256);

    /**
     * @notice Calculates the penalty fee for a given days range
     * @param index The index of the grace period record
     * @return The penalty fee as a mantissa between [0, 1e18]
     */
    function getPenaltyFee(uint8 index) external virtual view returns (uint256);

    /**
     * @notice Returns the penalty stages array
     */
    function getGracePeriod() external virtual view returns (GracePeriod[] memory);
    function getGracePeriodSnapshot() external virtual view returns (GracePeriod[] memory, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721/IERC721.sol";

abstract contract AssetInterface is IERC721 {
    bool public isAssetsFactory = true;

    function getTokenInfo(uint256 _tokenId) external virtual view returns (uint256, uint256, uint256, uint256, string memory, string memory, bool);
    function markAsRedeemed(uint256 tokenId) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);

    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    
    function transferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint tokenId) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint tokenId) external view returns (string memory);
}