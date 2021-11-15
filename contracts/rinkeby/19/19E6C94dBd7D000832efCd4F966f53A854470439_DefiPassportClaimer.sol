pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {Address} from "../../lib/Address.sol";
import {Ownable} from "../../lib/Ownable.sol";
import {ISapphireCreditScore} from "../../debt/sapphire/ISapphireCreditScore.sol";
import {SapphireTypes} from "../../debt/sapphire/SapphireTypes.sol";
import {IDefiPassport} from "./IDefiPassport.sol";

contract DefiPassportClaimer is Ownable {

    /* ========== Libraries ========== */

    using Address for address;

    /* ========== Events ========== */

    event CreditScoreContractSet(address _newContractAddress);

    event DefiPassportContractSet(address _newDefiPassportContract);

    /* ========== Public variables ========== */

    ISapphireCreditScore public creditScoreContract;

    IDefiPassport public defiPassport;

    /* ========== Constructor ========== */

    constructor(
        address _creditScoreContract,
        address _defiPassportContract
    )
        public
    {
        _setCreditScoreContract(_creditScoreContract);
        _setDefiPassportContract(_defiPassportContract);
    }

    /* ========== Restricted functions ========== */

    function setCreditScoreContract(
        address _creditScoreContract
    )
        external
        onlyOwner
    {
        _setCreditScoreContract(_creditScoreContract);
    }

    /* ========== Public functions ========== */

    /**
     * @notice Mints a passport to the user specified in the score proof
     *
     * @param _scoreProof The credit score proof of the receiver of the passport
     * @param _passportSkin The skin address of the passport
     * @param _skinId The ID of the skin NFT
     */
    function claimPassport(
        SapphireTypes.ScoreProof calldata _scoreProof,
        address _passportSkin,
        uint256 _skinId
    )
        external
    {
        creditScoreContract.verifyAndUpdate(_scoreProof);
        defiPassport.mint(
            _scoreProof.account,
            _passportSkin,
            _skinId
        );
    }

    /* ========== Private functions ========== */

    function _setCreditScoreContract(
        address _creditScoreContract
    )
        private
    {
        require(
            _creditScoreContract.isContract(),
            "DefiPassportClaimer: credit score address is not a contract"
        );

        require(
            address(creditScoreContract) != _creditScoreContract,
            "DefiPassportClaimer: cannot set the same contract address"
        );

        creditScoreContract = ISapphireCreditScore(_creditScoreContract);

        emit CreditScoreContractSet(_creditScoreContract);
    }

    function _setDefiPassportContract(
        address _defiPassportContract
    )
        private
    {
        require(
            _defiPassportContract.isContract(),
            "DefiPassportClaimer: defi passport address is not a contract"
        );

        require(
            address(defiPassport) != _defiPassportContract,
            "DefiPassportClaimer: cannot set the same contract address"
        );

        defiPassport = IDefiPassport(_defiPassportContract);

        emit DefiPassportContractSet(_defiPassportContract);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * @dev Collection of functions related to the address type.
 *      Take from OpenZeppelin at
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {SapphireTypes} from "./SapphireTypes.sol";

interface ISapphireCreditScore {
    function updateMerkleRoot(bytes32 newRoot) external;

    function setMerkleRootUpdater(address merkleRootUpdater) external;

    function verifyAndUpdate(SapphireTypes.ScoreProof calldata proof) external returns (uint256, uint16);

    function getLastScore(address user) external view returns (uint256, uint16, uint256);

    function setMerkleRootDelay(uint256 delay) external;

    function setPause(bool status) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

library SapphireTypes {

    struct ScoreProof {
        address account;
        uint256 score;
        bytes32[] merkleProof;
    }

    struct CreditScore {
        uint256 score;
        uint256 lastUpdated;
    }

    struct Vault {
        uint256 collateralAmount;
        uint256 borrowedAmount;
    }

    enum Operation {
        Deposit,
        Withdraw,
        Borrow,
        Repay,
        Liquidate
    }

    struct Action {
        uint256 amount;
        Operation operation;
        address userToLiquidate;
    }

}

pragma solidity 0.5.16;

contract IDefiPassport {
    function mint(
        address _to,
        address _passportSkin,
        uint256 _skinTokenId
    )
        external
        returns (uint256);
}

