// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

import "../interfaces/IStatistics.sol";
import "../abstractContracts/Base.sol";

contract Statistics is Base, IStatistics {

    event ExecutedIncreaseTotalFights();
    event ExecutedIncreaseTotalPoosStat();
    event ExecutedIncreaseTotalDumplingsStat();
    event ExecutedIncreaseTotalPoosSales();
    event ExecutedIncreaseTotalDumplingsSales();
    event ExecutedIncreaseTotalPowerUpsBought();

    uint public override totalFights;
    uint public override totalPoosStat;
    uint public override totalPoosSales;
    uint public override totalDumplingsStat;
    uint public override totalDumplingsSales;
    uint public override totalPowerUpsBought;

    constructor(address _constantsAddress) Base(_constantsAddress) {}

    function getContractStatistics() public override view returns (uint[8] memory) {
        address pooContract = IConstants(constantsContract).pooTokenContract();
        uint totalPooCap = IPooToken(pooContract).cap();
        uint totalPooTotalSupply = IPooToken(pooContract).totalSupply();
        return (
        [
        totalFights,
        totalPoosStat,
        totalPoosSales,
        totalDumplingsStat,
        totalDumplingsSales,
        totalPowerUpsBought,
        totalPooCap,
        totalPooTotalSupply
        ]);
    }

    /**
     *
     * @dev call for external contracts to adjust the totalFights value
     *
     */
    function increaseTotalFights() public override onlyAllowedContracts {
        totalFights = totalFights + 1;
        emit ExecutedIncreaseTotalFights();
    }

    /**
    *
    * @dev call for external contracts to adjust the totalPoosStat value
    *
    */
    function increaseTotalPoosStat() public override onlyAllowedContracts {
        totalPoosStat = totalPoosStat + 1;
        emit ExecutedIncreaseTotalPoosStat();
    }

    /**
    *
    * @dev call for external contracts to adjust the totalDumplingsStat value
    *
    */
    function increaseTotalDumplingsStat() public override onlyAllowedContracts {
        totalDumplingsStat = totalDumplingsStat + 1;
        emit ExecutedIncreaseTotalDumplingsStat();
    }

    /**
     *
     * @dev call for external contracts to adjust the totalPoosSales value
     *
     */
    function increaseTotalPoosSales() public override onlyAllowedContracts {
        totalPoosSales = totalPoosSales + 1;
        emit ExecutedIncreaseTotalPoosSales();
    }

    /**
 *
 * @dev call for external contracts to adjust the totalDumplingsSales value
 *
 */
    function increaseTotalDumplingsSales() public override onlyAllowedContracts {
        totalDumplingsSales = totalDumplingsSales + 1;
        emit ExecutedIncreaseTotalDumplingsSales();
    }

    /**
     *
     * @dev call for external contracts to adjust the totalPowerUpsBought value
     *
     */
    function increaseTotalPowerUpsBought(uint _newPowerUpsBought) public override onlyAllowedContracts {
        totalPowerUpsBought = totalPowerUpsBought + _newPowerUpsBought;
        emit ExecutedIncreaseTotalPowerUpsBought();
    }

}

// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

interface IStatistics {
    function totalFights() external view returns (uint);

    function totalPoosStat() external view returns (uint);

    function totalPoosSales() external view returns (uint);

    function totalDumplingsStat() external view returns (uint);

    function totalDumplingsSales() external view returns (uint);

    function totalPowerUpsBought() external view returns (uint);

    function increaseTotalFights() external;

    function increaseTotalPoosStat() external;

    function increaseTotalDumplingsStat() external;

    function increaseTotalPoosSales() external;

    function increaseTotalDumplingsSales() external;

    function increaseTotalPowerUpsBought(uint _newPowerUpsBought) external;

    function getContractStatistics() external view returns (uint[8] memory);

}

// SPDX-License-Identifier: POOMANIA
pragma solidity ^0.8.9;

import "../interfaces/IERC20Burnable.sol";


interface IPooToken is IERC20Burnable {

    function mintAdditionalRewards(address _receiver, uint _amount) external;

    function cap() external view returns (uint256);

}

// SPDX-License-Identifier: POOMANIA
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

interface IConstants {

    function statisticsContract() external view returns (address);

    function helpersContract() external view returns (address);

    function PooFightContract() external view returns (address);

    function DumplingFightContract() external view returns (address);

    function pooTokenContract() external view returns (address);

    function userAccountContract() external view returns (address);

    function PoosContract() external view returns (address);

    function PooLevelHandlerContract() external view returns (address);

    function PoosMarketplaceContract() external view returns (address);

    function PooPowerUpHandlerContract() external view returns (address);

    function PooTamagotchiContract() external view returns (address);

    function DumplingsContract() external view returns (address);

    function DumplingLevelHandlerContract() external view returns (address);

    function DumplingsMarketplaceContract() external view returns (address);

    function DumplingPowerUpHandlerContract() external view returns (address);

    function DumplingTamagotchiContract() external view returns (address);

    function tokenAmountForMint() external view returns (uint);

    function pooTokenForFeed() external view returns (uint);

    function pooTokenForInstantExhaustionReset() external view returns (uint);

    function pooTokenForResurrect() external view returns (uint);

    function pooTokenForRenamePoo() external view returns (uint);

    function pooTokenForFight() external view returns (uint);

    function pooTokenForDumplingMint() external view returns (uint);

    function pooTokenForHundredPowerUp() external view returns (uint);

    function pooTokenForTwoHundredPowerUp() external view returns (uint);

    function pooTokenForThreeHundredPowerUp() external view returns (uint);

    function winnerXp() external view returns (uint);

    function loserXp() external view returns (uint);

    function owner() external view returns (address);

    function rev() external view returns (address);

    function blocksBetweenRestPoint() external view returns (uint);

    function blocksBetweenHungerPointForPoo() external view returns (uint);

    function blocksBetweenHungerPointForDumpling() external view returns (uint);

    function saleFeePercentage() external view returns (uint);

    function fightExhaustion() external view returns (uint);

    function dumplingsPercentageOfParent() external view returns (uint);

    function blocksBetweenDumplingMintForPoo() external view returns (uint);

    function blocksBetweenPooRewardForRandomFights() external view returns (uint);

    function blocksBetweenPooRewardForIndividualFights() external view returns (uint);

    function pooRewardForFight() external view returns (uint);

    function baseBlockBetweenDumplingMint() external view returns (uint);

    function ownerRewardPercentage() external view returns (uint);

    function revRewardPercentage() external view returns (uint);

    function maxMintableDumplingsForPoo() external view returns (uint);

    function pooMintCosts() external view returns (uint);

}

// SPDX-License-Identifier: POOMANIA
pragma solidity ^0.8.9;

import "../interfaces/IPooToken.sol";
import "../interfaces/IConstants.sol";

abstract contract Base {

    event AllowedContractAdded(address indexed _contract);
    event AllowedContractRemoved(address indexed _contract);
    event ConstantsContractChanged(address indexed _contract);

    address public constantsContract;
    mapping(address => bool) public allowedContracts;

    constructor(address _constants) {
        constantsContract = _constants;
    }

    modifier onlyOwner {
        require(msg.sender == IConstants(constantsContract).owner(), "The sender of the message needs to be the contract owner.");
        _;
    }

    modifier onlyAllowedContracts {
        require(allowedContracts[msg.sender] == true, "The sender of the message needs to be an allowed contract.");
        _;
    }

    /**
     *
     * @dev
     * allows the owner to set the external addresses which are allowed to call the functions of this contract
     *
     */
    function addAllowedContract(address _allowedContract) public onlyOwner {
        allowedContracts[_allowedContract] = true;
        emit AllowedContractAdded(_allowedContract);
    }

    /**
     *
     * @dev
     * allows the owner to remove one external addresses which is no longer allowed to call the functions of this contract
     *
     */
    function removeAllowedContract(address _allowedContractToRemove) public onlyOwner {
        allowedContracts[_allowedContractToRemove] = false;
        emit AllowedContractRemoved(_allowedContractToRemove);
    }

    function setConstantsContract(address _newConstantsContract) public onlyOwner {
        constantsContract = _newConstantsContract;
        emit ConstantsContractChanged(_newConstantsContract);
    }

    function payByPoo(uint amount) internal {
        address pooContract = IConstants(constantsContract).pooTokenContract();
        require(IPooToken(pooContract).allowance(msg.sender, address(this)) >= amount, "Not enough allowance.");
        IPooToken(pooContract).burnFrom(msg.sender, amount);
    }

    function transferValueToOwner(uint value) internal {
        payable(IConstants(constantsContract).owner()).transfer(value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}