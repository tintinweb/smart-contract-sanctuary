// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./interface/IFwgPaymentDoc.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FwgPaymentDoc is ERC1155, IFwgPaymentDoc, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint public DefaultApprovalExpirationPeriod;

    // DocType mapping
    mapping(FwgPayDocType => uint) public maxEndorses;

    // TokenId mapping
    mapping(uint256 => FwgPayDocStatus) internal payDocStatus;
    mapping(uint256 => uint256) internal maturityTimes;
    mapping(uint256 => bool) internal guarantees;
    mapping(uint256 => address) internal certifiers;
    mapping(uint256 => address) internal owners;
    mapping(uint256 => string) internal tokenURIs;
    mapping(uint256 => FwgPayDocType) internal types;
    mapping(uint256 => uint256) internal versions;
    mapping(uint256 => uint256) internal endorses;

    // HoldId mapping
    mapping(bytes32 => FwgHoldData) internal holds;
    mapping(address => uint256) internal accountHoldBalances;
    mapping(address => mapping(uint256 => uint256)) internal accountHoldBalancesByTokenId;
    mapping(bytes32 => bytes32) internal _holdHashToId;
    uint256 override public totalSupplyOnHold;

    modifier isHeld(bytes32 holdId) {
        require(
            holds[holdId].status == FwgHoldType.Issuance ||
            holds[holdId].status == FwgHoldType.Certification ||
            holds[holdId].status == FwgHoldType.Maturity ||
            holds[holdId].status == FwgHoldType.Deposit ||
            holds[holdId].status == FwgHoldType.Endorse,
            "Hold is not in Held status"
        );
        _;
    }
    
    constructor(uint _expirationPeriod, uint _maxCheckEndorses, uint _maxPromissoryNoteEndorses) ERC1155("") {
        DefaultApprovalExpirationPeriod = _expirationPeriod;
        maxEndorses[FwgPayDocType.Check] = _maxCheckEndorses;
        maxEndorses[FwgPayDocType.PromissoryNote] = _maxPromissoryNoteEndorses;
        _tokenIdCounter.increment(); //Default value is 0, increment to be tokenId=1 first asset minted
    }

    function generateHoldId(
        address sender,
        address recipient,
        address notary,
        uint256 tokenId,
        uint256 version,
        uint256 amount,
        uint256 expirationDateTime,
        bytes32 lockHash
    ) public pure returns (bytes32 holdId) {
        holdId = keccak256(
            abi.encodePacked(
                sender,
                recipient,
                notary,
                tokenId,
                version,
                amount,
                expirationDateTime,
                lockHash
            )
        );
    }

    /**
    * @dev Retrieve hold hash, and ID for given parameters
    */
    function retrieveHoldHashId(address notary, address sender, address recipient, uint256 tokenId, uint256 version, uint value) public view returns (bytes32, bytes32) {
        // Pack and hash hold parameters
        bytes32 holdHash = keccak256(abi.encodePacked(
            address(this), //Include the token address to indicate domain
            sender,
            recipient,
            notary,
            tokenId,
            version,
            value
        ));
        bytes32 holdId = _holdHashToId[holdHash];

        return (holdHash, holdId);
    }  

    /**
     @notice Called by the sender to hold some tokens for a recipient that the sender can not release back to themself until after the expiration date.
     @param holdId a unique identifier for the hold.
     @param sender account to hold the tokens, tipically the sender and owner of token
     @param recipient optional account the tokens will be transferred to on execution. If a zero address, the recipient must be specified on execution of the hold.
     @param notary account that can execute the hold. Typically the recipient but can be a third party or a smart contact.
     @param amount of tokens to be transferred to the recipient on execution. Must be a non zero amount.
     @param tokenId - tokenId to apply hold
     @param expirationDateTime UNIX epoch seconds the held amount can be released back to the sender by the sender. Past dates are allowed.
     @param lockHash optional keccak256 hash of a lock preimage. An empty hash will not enforce the hash lock when the hold is executed.
     */
    function hold(
        bytes32 holdId,
        address sender,
        address recipient,
        address notary,
        uint256 tokenId,
        uint256 amount,
        uint256 expirationDateTime,
        bytes32 lockHash,
        FwgHoldType status
    ) internal {
        require(
            sender != address(0),
            "hold: sender must not be a zero address"
        );

        require(
            notary != address(0),
            "hold: notary must not be a zero address"
        );
        require(amount != 0, "hold: amount must be greater than zero");
        require(
            this.spendableBalanceOf(sender, tokenId) >= amount,
            "hold: amount exceeds available balance"
        );
        
        (bytes32 holdHash,) = retrieveHoldHashId(
            notary,
            sender,
            recipient,
            tokenId,
            versions[tokenId],
            amount
        );
        _holdHashToId[holdHash] = holdId;

        require(
            holds[holdId].status == FwgHoldType.Undefined,
            "hold: id already exists"
        );
        holds[holdId] = FwgHoldData(
            sender,
            recipient,
            notary,
            tokenId,
            amount,
            expirationDateTime,
            lockHash,
            status
        );
        accountHoldBalances[sender] = accountHoldBalances[sender].add(
            amount
        );

        accountHoldBalancesByTokenId[sender][tokenId] = accountHoldBalancesByTokenId[sender][tokenId].add(
            amount
        );

        totalSupplyOnHold = totalSupplyOnHold.add(amount);

        emit NewHold(
            holdId,
            sender,
            recipient,
            notary,
            tokenId,
            amount,
            expirationDateTime,
            lockHash
        );
    }

    function retrieveHoldData(bytes32 holdId) external override view returns (FwgHoldData memory) {
        return holds[holdId];
    }

    function retrievePaymentStatus(uint256 id) external override view returns (FwgPayDocStatus) {
        return payDocStatus[id];
    }

    function retrieveCertifier(uint256 id) external override view returns (address) {
        return certifiers[id];
    }

    function retrieveGuaranteed(uint256 id) external override view returns (bool) {
        return guarantees[id];
    }

    function retrieveDocType(uint256 id) external override view returns (FwgPayDocType) {
        return types[id];
    }

    function retrieveOwnerToken(uint256 id) external override view returns (address) {
        return owners[id];
    }

    /**
     @notice Called by the notary to transfer the held tokens to the set at the hold recipient if there is no hash lock.
     @param holdId a unique identifier for the hold.
     */
    function executeHold(bytes32 holdId) internal {
        require(
            holds[holdId].recipient != address(0),
            "executeHold: must pass the recipient on execution as the recipient was not set on hold"
        );
        require(
            holds[holdId].secretHash == bytes32(0),
            "executeHold: need preimage if the hold has a lock hash"
        );

        _executeHold(holdId, holds[holdId].recipient);
    }

    /**
     @notice Called by the notary to transfer the held tokens to the recipient that was set at the hold.
     @param holdId a unique identifier for the hold.
     @param lockPreimage the image used to generate the lock hash with a sha256 hash
     */
    function executeHold(bytes32 holdId, bytes32 lockPreimage) internal {
        require(
            holds[holdId].recipient != address(0),
            "executeHold: must pass the recipient on execution as the recipient was not set on hold"
        );
        if (holds[holdId].secretHash != bytes32(0)) {
            require(
                holds[holdId].secretHash ==
                    sha256(abi.encodePacked(lockPreimage)),
                "executeHold: preimage hash does not match lock hash"
            );
        }

        _executeHold(holdId, holds[holdId].recipient);
    }

    /**
     @notice Called by the notary to transfer the held tokens to the recipient if no recipient was specified at the hold.
     @param holdId a unique identifier for the hold.
     @param lockPreimage the image used to generate the lock hash with a keccak256 hash
     @param recipient the account the tokens will be transferred to on execution.
     */
    function executeHold(
        bytes32 holdId,
        bytes32 lockPreimage,
        address recipient
    ) internal {
        require(
            holds[holdId].recipient == address(0),
            "executeHold: can not set a recipient on execution as it was set on hold"
        );
        require(
            recipient != address(0),
            "executeHold: recipient must not be a zero address"
        );
        if (holds[holdId].secretHash != bytes32(0)) {
            require(
                holds[holdId].secretHash ==
                    sha256(abi.encodePacked(lockPreimage)),
                "executeHold: preimage hash does not match lock hash"
            );
        }

        holds[holdId].recipient = recipient;

        _executeHold(holdId, recipient);
    }

    function _executeHold(
        bytes32 holdId,
        address recipient
    ) internal isHeld(holdId) {
        require(
            holds[holdId].notary == msg.sender,
            "executeHold: caller must be the hold notary"
        );

        super._safeTransferFrom(holds[holdId].sender, recipient, holds[holdId].tokenId, holds[holdId].amount, "0x0");
        owners[holds[holdId].tokenId] = recipient;

        holds[holdId].status = FwgHoldType.Executed;
        accountHoldBalances[holds[holdId]
            .sender] = accountHoldBalances[holds[holdId].sender].sub(
            holds[holdId].amount
        );

        accountHoldBalancesByTokenId[holds[holdId].sender][holds[holdId].tokenId] = accountHoldBalancesByTokenId[holds[holdId].sender][holds[holdId].tokenId].sub(
            holds[holdId].amount
        );

        totalSupplyOnHold = totalSupplyOnHold.sub(holds[holdId].amount);

        (bytes32 holdHash,) = retrieveHoldHashId(
            holds[holdId].notary,
            holds[holdId].sender,
            holds[holdId].recipient,
            holds[holdId].tokenId,
            versions[holds[holdId].tokenId],
            holds[holdId].amount
        );
        delete _holdHashToId[holdHash];

        //emit ExecutedHold(holdId, lockPreimage, recipient);
    }

    /**
     @notice Called by the notary at any time or the sender after the expiration date to release the held tokens back to the sender.
     @param holdId a unique identifier for the hold.
     */
    function closeHold(bytes32 holdId) internal isHeld(holdId) {
        if (holds[holdId].sender == msg.sender) {
            require(
                block.timestamp > holds[holdId].expirationDateTime,
                "closeHold: can only release after the expiration date."
            );
        } else if (holds[holdId].notary != msg.sender) {
            revert("closeHold: caller must be the hold sender or notary.");
        }

        holds[holdId].status = FwgHoldType.Closed;

        accountHoldBalances[holds[holdId]
            .sender] = accountHoldBalances[holds[holdId].sender].sub(
            holds[holdId].amount
        );

        accountHoldBalancesByTokenId[holds[holdId]
            .sender][holds[holdId].tokenId] = accountHoldBalancesByTokenId[holds[holdId].sender][holds[holdId].tokenId].sub(
            holds[holdId].amount
        );

        totalSupplyOnHold = totalSupplyOnHold.sub(holds[holdId].amount);
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(owners[tokenId] != address(0), "tokenURI: URI query for nonexistent token");
        return tokenURIs[tokenId];
    }

    function mintAndHold(address to, address beneficiary, address certifier, bool guaranteed, uint256 maturityTime, FwgPayDocType docType, string memory payDocURI, bytes memory data) public onlyOwner override {
        require(
            to != beneficiary,
            "mintAndHold: sender need to be different to beneficiary"
        );

        require(
            docType == FwgPayDocType.Check || docType == FwgPayDocType.PromissoryNote,
            "mintAndHold: docType not a valid value"
        );
        
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId, 1, data);
        _tokenIdCounter.increment();

        maturityTimes[tokenId] = maturityTime;
        tokenURIs[tokenId] = payDocURI;
        guarantees[tokenId] = guaranteed;
        certifiers[tokenId] = certifier;
        types[tokenId] = docType;
        versions[tokenId] = 1;
        endorses[tokenId] = 0;
        owners[tokenId] = to;
        bytes32 holdId = generateHoldId(to, beneficiary, beneficiary, tokenId, versions[tokenId], 1, DefaultApprovalExpirationPeriod, "");
        hold(holdId, to, beneficiary, beneficiary, tokenId, 1, DefaultApprovalExpirationPeriod, "", FwgHoldType.Issuance);
        emit Issuance(tokenId, to, beneficiary, certifier, guaranteed, maturityTime, payDocURI);
        payDocStatus[tokenId] = FwgPayDocStatus.FilledHeld;
    }

    function accept(bytes32 holdId) public override {
        require(
            holds[holdId].status != FwgHoldType.Undefined,
            "accept: hold type need to be different to Undefined"
        );
        uint256 tokenId = holds[holdId].tokenId;
        FwgPayDocStatus actualStatus = payDocStatus[tokenId];

        require(
            actualStatus == FwgPayDocStatus.FilledHeld ||
            actualStatus == FwgPayDocStatus.WaitingCertification ||
            actualStatus == FwgPayDocStatus.IssuedValidated ||
            actualStatus == FwgPayDocStatus.PendingDeposit,
            "accept: no accept action available for that hold"
        );

        if (actualStatus == FwgPayDocStatus.FilledHeld) {
            executeHold(holdId);
            emit IssuanceAccepted(tokenId);
            if (certifiers[tokenId] == address(0)) {
                // No hay certificador
                bytes32 newHoldId = generateHoldId(holds[holdId].recipient, holds[holdId].recipient, owner(), tokenId, versions[tokenId], 1, maturityTimes[tokenId], "");
                hold(newHoldId, holds[holdId].recipient, holds[holdId].recipient, owner(), tokenId, 1, maturityTimes[tokenId], "", FwgHoldType.Maturity);
                payDocStatus[tokenId] = FwgPayDocStatus.IssuedValidated;
            } else {
                // Hay certificador
                emit WaitingCertification(tokenId, certifiers[tokenId]);
                bytes32 newHoldId = generateHoldId(holds[holdId].recipient, holds[holdId].recipient, certifiers[tokenId], tokenId, versions[tokenId], 1, DefaultApprovalExpirationPeriod, "");
                hold(newHoldId, holds[holdId].recipient, holds[holdId].recipient, certifiers[tokenId], tokenId, 1, DefaultApprovalExpirationPeriod, "", FwgHoldType.Certification);
                payDocStatus[tokenId] = FwgPayDocStatus.WaitingCertification;
            }
        } else if (actualStatus == FwgPayDocStatus.WaitingCertification) {
            executeHold(holdId);
            emit CertificationAccepted(tokenId, holds[holdId].notary);
            bytes32 newHoldId = generateHoldId(holds[holdId].recipient, holds[holdId].recipient, owner(), tokenId, versions[tokenId], 1, maturityTimes[tokenId], "");
            hold(newHoldId, holds[holdId].recipient, holds[holdId].recipient, owner(), tokenId, 1, maturityTimes[tokenId], "", FwgHoldType.Maturity);
            payDocStatus[tokenId] = FwgPayDocStatus.IssuedValidated;
        } else if (actualStatus == FwgPayDocStatus.IssuedValidated) {
            require(
                holds[holdId].status == FwgHoldType.Endorse,
                "accept: hold type need to be Endorse to accept with this payment status"
            );
            executeHold(holdId);
            emit EndorsementAccepted(tokenId, holds[holdId].recipient);
            endorses[tokenId]++;
            bytes32 newHoldId = generateHoldId(holds[holdId].recipient, holds[holdId].recipient, owner(), tokenId, versions[tokenId], 1, maturityTimes[tokenId], "");
            hold(newHoldId, holds[holdId].recipient, holds[holdId].recipient, owner(), tokenId, 1, maturityTimes[tokenId], "", FwgHoldType.Maturity);
        } else if (actualStatus == FwgPayDocStatus.PendingDeposit) {
            executeHold(holdId);
            emit DepositAccepted(tokenId);
            payDocStatus[tokenId] = FwgPayDocStatus.Deposited;
        }
    }

    function reject(bytes32 holdId) public override {
        require(
            holds[holdId].status != FwgHoldType.Undefined,
            "reject: hold type need to be different to Undefined"
        );

        uint256 tokenId = holds[holdId].tokenId;
        FwgPayDocStatus actualStatus = payDocStatus[tokenId];

        require(
            actualStatus == FwgPayDocStatus.FilledHeld ||
            actualStatus == FwgPayDocStatus.WaitingCertification ||
            actualStatus == FwgPayDocStatus.IssuedValidated ||
            actualStatus == FwgPayDocStatus.PendingDeposit,
            "reject: no reject action available for that hold"
        );

        if (actualStatus == FwgPayDocStatus.IssuedValidated) { //Only for reject endorses, no burn, hold rollback
            require(
                holds[holdId].status == FwgHoldType.Endorse,
                "reject: hold type need to be Endorse to reject with this payment status"
            );

            closeHold(holdId);
            emit EndorsementRejected(tokenId, holds[holdId].recipient);
            bytes32 newHoldId = generateHoldId(holds[holdId].sender, holds[holdId].sender, owner(), tokenId, versions[tokenId], 1, maturityTimes[tokenId], "");
            hold(newHoldId, holds[holdId].sender, holds[holdId].sender, owner(), tokenId, 1, maturityTimes[tokenId], "", FwgHoldType.Maturity);
        } else {
            closeHold(holdId);

            if (actualStatus == FwgPayDocStatus.FilledHeld) {
                emit IssuanceRejected(tokenId);
            } else if (actualStatus == FwgPayDocStatus.WaitingCertification) {
                emit CertificationRejected(tokenId, holds[holdId].notary);
            } else if (actualStatus == FwgPayDocStatus.PendingDeposit) {
                emit DepositRejected(tokenId);
            }

            super._burn(owners[tokenId], tokenId, 1);
            payDocStatus[tokenId] = FwgPayDocStatus.Cancelled;
            owners[tokenId] = address(0);
        }
    }

    function deposit(bytes32 holdId) public override {
        require(
            holds[holdId].status == FwgHoldType.Maturity,
            "deposit: hold type need to be Maturity to deposit"
        );

        if (msg.sender == holds[holdId].sender) { // Called by sender (need to release if maturityTime done)
            closeHold(holdId);
        } else { // Called by bank (notary)
            executeHold(holdId);
        }

        uint256 tokenId = holds[holdId].tokenId;

        emit PendingDeposit(tokenId);
        bytes32 newHoldId = generateHoldId(holds[holdId].recipient, owner(), owner(), tokenId, versions[tokenId], 1, DefaultApprovalExpirationPeriod, "");
        hold(newHoldId, holds[holdId].sender, owner(), owner(), tokenId, 1, DefaultApprovalExpirationPeriod, "", FwgHoldType.Deposit);
        payDocStatus[tokenId] = FwgPayDocStatus.PendingDeposit;
    }

    function requestEndorsement(bytes32 holdId, address newBeneficiary) public override { // TODO: Add payDocURI IPFS?
        require(
            holds[holdId].status == FwgHoldType.Maturity,
            "requestEndorsement: hold type need to be Maturity to endorse"
        );

        require(
            holds[holdId].recipient != newBeneficiary,
            "requestEndorsement: new beneficiary need to be different to actual beneficiary"
        );

        uint256 tokenId = holds[holdId].tokenId;
        
        require(
            endorses[tokenId] < maxEndorses[types[tokenId]],
            "requestEndorsement: max endorsements reached"
        );

        versions[tokenId]++;
        closeHold(holdId); //TODO: Quien pide el Endorsement no es el notary!!! Que lo pida el bank???
        emit WaitingEndorsement(tokenId, newBeneficiary);
        bytes32 newHoldId = generateHoldId(holds[holdId].sender, newBeneficiary, newBeneficiary, tokenId, versions[tokenId], 1, DefaultApprovalExpirationPeriod, "");
        hold(newHoldId, holds[holdId].sender, newBeneficiary, newBeneficiary, tokenId, 1, DefaultApprovalExpirationPeriod, "", FwgHoldType.Endorse);
    }

    /**
     @notice Set the maximum endorses quantity
     @param docType The type of payment document
     @param newMaxEndorses the new maximum for Check endorses
     */
    function setMaxEndorses(FwgPayDocType docType, uint newMaxEndorses) public onlyOwner override {
        maxEndorses[docType] = newMaxEndorses;
    }

    /**
     @notice Total amount of tokens owned by an account including all the held tokens pending execution or release.
     @param account owner of the tokens
     @param id tokenID to check
     */
    function balanceOf(address account, uint256 id) public override(ERC1155, IERC1155) view returns (uint256) {
        return super.balanceOf(account, id);
    }

    /**
     @notice Amount of tokens owned by an account that are held pending execution or release.
     @param account owner of the tokens
     @param id tokenId to check
     */
    function balanceOnHold(address account, uint256 id) public override view returns (uint256) {
        return accountHoldBalancesByTokenId[account][id];
    }

    /**
     @notice Amount of tokens owned by an account that are available for transfer. That is, the gross balance less any held tokens.
     @param account owner of the tokens
     @param id tokenId to check
     */
    function spendableBalanceOf(address account, uint256 id) public override view returns (uint256) {
        return balanceOf(account, id).sub(accountHoldBalancesByTokenId[account][id]);
    }

    /**
     @param holdId a unique identifier for the hold.
     @return hold status code.
     */
    function holdStatus(bytes32 holdId) public override view returns (FwgHoldType) {
        return holds[holdId].status;
    }

    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155, IERC1155) {
        require(
            this.spendableBalanceOf(sender, id) >= amount,
            "HoldableToken: amount exceeds available balance"
        );
        super.safeTransferFrom(sender, recipient, id, amount, data);
    }
    // TODO: Deletes to free up array spaces??
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
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
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// contracts/IERC1155HoldableToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./FwgStatusData.sol";

/**
 * @title Holdable ERC1155 Token Interface.
 * @dev like approve except the tokens can't be spent by the sender while they are on hold.
 */
interface IFwgPaymentDoc is IERC1155 {

    event NewHold(bytes32 indexed holdId, address indexed sender, address indexed recipient, address notary, uint256 tokenId, uint256 amount, uint256 expirationDateTime, bytes32 lockHash);
    event Issuance(uint256 indexed tokenId, address indexed sender, address indexed beneficiary, address certifier, bool guaranteed, uint256 maturityTime, string payDocURI);
    event WaitingCertification(uint256 indexed tokenId, address indexed certifier);
    event CertificationAccepted(uint256 indexed tokenId, address indexed certifier);
    event CertificationRejected(uint256 indexed tokenId, address indexed certifier);
    event IssuanceAccepted(uint256 indexed tokenId);
    event IssuanceRejected(uint256 indexed tokenId);
    event WaitingEndorsement(uint256 indexed tokenId, address indexed newBeneficiary);
    event EndorsementAccepted(uint256 indexed tokenId, address indexed newBeneficiary);
    event EndorsementRejected(uint256 indexed tokenId, address indexed newBeneficiary);
    event PendingDeposit(uint256 indexed tokenId);
    event DepositAccepted(uint256 indexed tokenId);
    event DepositRejected(uint256 indexed tokenId);

    /**
     @notice Called by the sender to hold some tokens for a recipient that the sender can not release back to themself until after the expiration date.
     @param to account to mint the token and start the payment, the sender
     @param beneficiary account that will receive the token with the payment
     @param certifier optional account that is the certifier of the payment
     @param guaranteed true if bank reserved funds before calling, false otherwise
     @param maturityTime UNIX epoch seconds the payment can be deposited by the beneficiary. Past dates are allowed.
     @param payDocURI IPFS CID of the signed PDF for the payment
     @param data data to be indicated when minting token (if empty need to fill: 0x0)
     */
    function mintAndHold(
        address to,
        address beneficiary,
        address certifier,
        bool guaranteed,
        uint256 maturityTime,
        FwgPayDocType docType,
        string memory payDocURI,
        bytes memory data
    ) external;

    function retrieveHoldData(bytes32 holdId) external view returns (FwgHoldData memory);

    function retrievePaymentStatus(uint256 id) external view returns (FwgPayDocStatus);

    function retrieveCertifier(uint256 id) external view returns (address);

    function retrieveGuaranteed(uint256 id) external view returns (bool);

    function retrieveDocType(uint256 id) external view returns (FwgPayDocType);

    function retrieveOwnerToken(uint256 id) external view returns (address);

    /**
     @notice Called by the beneficiary or the certifier or the bank to accept payment or accept certification or accept deposit, transfer the held token and create a new one hold to the next actor.
     @param holdId a unique identifier for the hold.
     */
    function accept(bytes32 holdId) external;

    /**
     @notice Called by the beneficiary ot the certifier to reject payment or certificacion or deposit, release the held and burn token.
     @param holdId a unique identifier for the hold.
     */
    function reject(bytes32 holdId) external;

    /**
     @notice Called by the beneficiary to deposit the payment
     @param holdId a unique identifier for the hold.
     */
    function deposit(bytes32 holdId) external;

    /**
     @notice Called by the beneficiary to endorse the payment
     @param holdId a unique identifier for the hold.
     @param newBeneficiary new beneficiary of payment
     */
    function requestEndorsement(bytes32 holdId, address newBeneficiary) external;

    /**
     @notice Set the maximum endorses quantity
     @param docType The type of payment document
     @param newMaxEndorses the new maximum for Check endorses
     */
    function setMaxEndorses(FwgPayDocType docType, uint newMaxEndorses) external;

    /**
     @notice Amount of tokens owned by an account that are held pending execution or release.
     @param account owner of the tokens
     */
    function balanceOnHold(address account, uint256 id) external view returns (uint256);

    /**
      @notice Amount of tokens owned by an account that are available for transfer. That is, the gross balance less any held tokens.
     @param account owner of the tokens
     */
    function spendableBalanceOf(address account, uint256 id) external view returns (uint256);

    function totalSupplyOnHold() external view returns (uint256);

    /**
     @param holdId a unique identifier for the hold.
     @return hold status code.
     */
    function holdStatus(bytes32 holdId) external view returns (FwgHoldType);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

enum FwgHoldType {
    Undefined, 
    Issuance, 
    Certification, 
    Maturity,
    Endorse,
    Deposit,
    Executed,
    Closed
}

struct FwgHoldData {
    address sender;
    address recipient;
    address notary;
    uint256 tokenId;
    uint256 amount;
    uint256 expirationDateTime;
    bytes32 secretHash;
    FwgHoldType status;
}

enum FwgPayDocStatus {
    Undefined,
    FilledHeld,
    WaitingCertification,
    IssuedValidated,
    PendingDeposit,
    Deposited,
    Cancelled
}

enum FwgPayDocType {
    Check,
    PromissoryNote
}