// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @summary: Forked & Modified Vether (vetherasset.io) contract for Public Sale
 * @author: Boot Finance
 */

import "IERC721.sol";
import "SafeERC20.sol";
import "Ownable.sol";
import "Pausable.sol";

interface IVesting {
   /**
    * @dev Interface to vesting contract. 30% tokens are released instantly, 70% are locked.
    * @param _beneficiary Beneficiary of the locked tokens.
    * @param _amount Amount to be locked in vesting contract.
    */
   function vest(address _beneficiary, uint256 _amount) external payable;
}

interface IMintable {
    function mint(address _to, uint256 _value) external;
}

library SafeMath {
    /**
     * @dev SafeMath library
     * @param a First variable
     * @param b Second variable
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

contract BasicAuction is Ownable, Pausable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public immutable mainToken;  //          BOOT token
    IERC721 public immutable nft;       // NFT contract required for early access

    // Public Parameters
    uint public constant decimals = 18;
    uint public constant coin = 10 ** decimals;
    uint public constant firstEra = 1;

    // project-specific multisig address where raised funds will be sent
    address payable destAddress;

    uint public secondsPerAuction;
    uint public auctionsPerEra;
    uint public firstPublicAuction;
    uint public totalSupply;        // MainToken supply allocated to public sale
    uint public remainingSupply;
    uint public initialEmission;
    uint public emissionDecayRate; // e.g. 1_000 constant, 0_618 golden ratio decay
    uint public currentEra;
    uint public currentAuction;
    uint public nextEraTime;
    uint public nextAuctionTime;
    uint public totalContributed;
    uint public totalEmitted;
    uint public ewma;
    uint private emission;

    // The emission for all auctions within a particular era.
    mapping(uint => uint) public mapEra_Emission;
    // The number of participants in a particular auction in a particular era.
    mapping(uint => mapping(uint => uint)) public mapEraAuction_MemberCount;
    // The participants in a particular auction in a particular era.
    mapping(uint => mapping(uint => address[])) public mapEraAuction_Members;
    // The total units contributed in a particular auction in a particular era.
    mapping(uint => mapping(uint => uint)) public mapEraAuction_Units;
    // The remaining unclaimed units from a particular auction in a particular era.
    mapping(uint => mapping(uint => uint)) public mapEraAuction_UnitsRemaining;
    // The remaining unclaimed tokens from a particular auction in a particular era.
    mapping(uint => mapping(uint => uint)) public mapEraAuction_EmissionRemaining;
    // Participant's remaining (unclaimed) units for a particular auction in a particular era
    mapping(uint => mapping(uint => mapping(address => uint))) public mapEraAuction_MemberUnitsRemaining;
    // Participant's particular auctions for a particular era.
    mapping(address => mapping(uint => uint[])) public mapMemberEra_Auctions;

    // Events
    event NewEra(uint era, uint emission, uint time, uint totalContributed);
    event NewAuction(uint era, uint auction, uint time, uint previousAuctionTotal, uint previousAuctionMembers, uint historicEWMA);
    event Contribution(address indexed payer, address indexed member, uint era, uint auction, uint units, uint dailyTotal);
    event Withdrawal(address indexed caller, address indexed member, uint era, uint auction, uint value, uint remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        IERC20 _mainToken,
        IERC721 _nft,
        uint _secondsPerAuction,
        uint _auctionsPerEra,
        uint _firstPublicAuction,
        uint _totalSupply,
        uint _initialEmission,
        uint _emissionDecayRate,
        address payable _destAddress)
    {
        require(address(_mainToken) != address(0), "Invalid _mainToken address");
        require(address(_nft) != address(0), "Invalid _nft address");
        require(address(_destAddress) != address(0), "Invalid _destAddress");

        mainToken = _mainToken;
        nft = _nft;

        currentEra = 1;
        currentAuction = 1;
        totalContributed = 0;
        totalEmitted = 0;

        secondsPerAuction = _secondsPerAuction;
        auctionsPerEra = _auctionsPerEra;
        firstPublicAuction = _firstPublicAuction;
        totalSupply = _totalSupply;
        initialEmission = _initialEmission;
        emissionDecayRate = _emissionDecayRate;

        emission = initialEmission; // current auction's theoretical emission regardless of actual supply
        remainingSupply = _totalSupply; // remaining actual supply including for the current auction

        destAddress = _destAddress;

        nextEraTime = block.timestamp + secondsPerAuction * auctionsPerEra;
        nextAuctionTime = block.timestamp + secondsPerAuction;
        mapEra_Emission[currentEra] = emission;
        mapEraAuction_EmissionRemaining[currentEra][currentAuction] = emission;
    }

    function setDestination(address payable _destAddress) public onlyOwner {
        require(address(_destAddress) != address(0), "Invalid _destAddress");
        destAddress = _destAddress;
    }

    receive() external payable whenNotPaused {
        // Any ETH sent is assumed to be for the token sale.
        _contributeForMember(msg.sender);
    }

    function contributeForMember(address member) external payable whenNotPaused {
        _contributeForMember(member);
    }

    function _contributeForMember(address member) private {
        require(msg.value > 0, "Some ether should be sent");
        _updateEmission();
        require(remainingSupply > 0, "public sale has ended");
        if (currentEra == 1 && currentAuction < firstPublicAuction) {
            // Initially only accounts with the specific NFT may participate.
            //
            require(nft.balanceOf(member) > 0, "NFT required to participate.");
        }
        _withdrawPrior(member);
        _recordContribution(msg.sender, member, currentEra, currentAuction, msg.value);
        (bool success, /*bytes memory data*/) = destAddress.call{value: msg.value}("");
        require(success, "");
    }

    function _recordContribution(address _payer, address _member, uint _era, uint _auction, uint _eth) private {
        if (mapEraAuction_MemberUnitsRemaining[_era][_auction][_member] == 0) {
            // If hasn't contributed to this Auction yet
            mapMemberEra_Auctions[_member][_era].push(_auction);
            mapEraAuction_MemberCount[_era][_auction] += 1;
            mapEraAuction_Members[_era][_auction].push(_member);
        }
        mapEraAuction_MemberUnitsRemaining[_era][_auction][_member] += _eth;
        mapEraAuction_Units[_era][_auction] += _eth;
        mapEraAuction_UnitsRemaining[_era][_auction] += _eth;
        totalContributed += _eth;
        emit Contribution(_payer, _member, _era, _auction, _eth, mapEraAuction_Units[_era][_auction]);
    }

    function getAuctionsContributedForEra(address member, uint era) public view returns(uint) {
        return mapMemberEra_Auctions[member][era].length;
    }

    function withdrawShare(uint era, uint auction) external returns (uint) {
        require(era >= 1, "era must be >= 1");
        require(auction >= 1, "auction must be >= 1");
        require(auction <= auctionsPerEra, "auction must be <= auctionsPerEra");
        _updateEmission();
        return _withdrawShare(era, auction, msg.sender);                           
    }

    function batchWithdraw(uint era, uint[] memory arrayAuctions) external returns (uint value) {
        _updateEmission();
        for (uint i = 0; i < arrayAuctions.length; ++i) {
            value += _prepareWithdrawShare(era, arrayAuctions[i], msg.sender);
        }
        _mint(value, msg.sender);
    }

    function _withdrawPrior(address member) private {
        for (uint era = currentEra; era >= 1; --era) {
            uint i = mapMemberEra_Auctions[member][era].length;
            while (i > 0) {
                --i;
                uint auction = mapMemberEra_Auctions[member][era][i];
                if (era != currentEra || auction != currentAuction) {
                    uint units = mapEraAuction_MemberUnitsRemaining[era][auction][member];
                    if (units > 0) {
                        uint value = _prepareWithdrawUnits(era, auction, member, units);
                        _mint(value, member);
                        //
                        // If a prior auction is found, then it is the only prior auction
                        // that has not already been withdrawn, so there's nothing left to do.
                        //
                        return;
                    }
                }
            }
        }
    }

    function withdrawAll(uint era) external returns (uint value) {
        _updateEmission();
        uint length = mapMemberEra_Auctions[msg.sender][era].length;
        for (uint i = 0; i < length; ++i) {
            uint auction = mapMemberEra_Auctions[msg.sender][era][i];
            value += _prepareWithdrawShare(era, auction, msg.sender);
        }
        _mint(value, msg.sender);
    }

    function withdrawAll() external returns (uint value) {
        _updateEmission();
        for (uint era = 1; era <= currentEra; ++era) {
            uint length = mapMemberEra_Auctions[msg.sender][era].length;
            for (uint i = 0; i < length; ++i) {
                uint auction = mapMemberEra_Auctions[msg.sender][era][i];
                value += _prepareWithdrawShare(era, auction, msg.sender);
            }
        }
        _mint(value, msg.sender);
    }

    function _mint(uint value, address _member) private {
        IMintable(address(mainToken)).mint(_member, value);
    }

    function _prepareWithdrawShare (uint _era, uint _auction, address _member) private returns (uint value) {
        if (_era < currentEra) {
            // Allow if in previous Era
            value = _prepareWithdrawal(_era, _auction, _member);
        }
        else if (_era == currentEra && _auction < currentAuction) {
            // Allow if in current Era and previous Auction
            value = _prepareWithdrawal(_era, _auction, _member);
        }
    }

    function _withdrawShare (uint _era, uint _auction, address _member) private returns (uint value) {
        // allowed from prior Era
        if (_era < currentEra) {
            value = _prepareWithdrawal(_era, _auction, _member);
            _mint(value, _member);
        }
        // allowed from prior Auction in current Era
        else if (_era == currentEra && _auction < currentAuction) {
            value = _prepareWithdrawal(_era, _auction, _member);
            _mint(value, _member);
        }  
    }

    function _prepareWithdrawal (uint _era, uint _auction, address _member) private returns (uint value) {
        uint memberUnits = mapEraAuction_MemberUnitsRemaining[_era][_auction][_member];
        if (memberUnits != 0) {
            value = _prepareWithdrawUnits(_era, _auction, _member, memberUnits);
        }
    }

    function _prepareWithdrawUnits(uint _era, uint _auction, address _member, uint memberUnits) private returns (uint value) {
        uint totalUnits = mapEraAuction_UnitsRemaining[_era][_auction];
        uint emissionRemaining = mapEraAuction_EmissionRemaining[_era][_auction];
        value = (emissionRemaining * memberUnits) / totalUnits;
        mapEraAuction_MemberUnitsRemaining[_era][_auction][_member] = 0; // since it will be withdrawn
        mapEraAuction_UnitsRemaining[_era][_auction] = mapEraAuction_UnitsRemaining[_era][_auction].sub(memberUnits);
        mapEraAuction_EmissionRemaining[_era][_auction] = mapEraAuction_EmissionRemaining[_era][_auction].sub(value);
        emit Withdrawal(msg.sender, _member, _era, _auction, value, mapEraAuction_EmissionRemaining[_era][_auction]);
    }

    // remaining emission share
    function getEmissionShare(uint era, uint auction, address member) public view returns (uint value) {
        uint memberUnits = mapEraAuction_MemberUnitsRemaining[era][auction][member];
        if (memberUnits != 0) {
            uint totalUnits = mapEraAuction_UnitsRemaining[era][auction];
            uint emissionRemaining = mapEraAuction_EmissionRemaining[era][auction];
            value = (emissionRemaining * memberUnits) / totalUnits;
        }
    }
    
    function _updateEmission() private {
        uint _now = block.timestamp;
        if (_now >= nextAuctionTime) {
            uint members = mapEraAuction_MemberCount[currentEra][currentAuction];
            uint units = mapEraAuction_Units[currentEra][currentAuction];
			if (units > 0) {
				uint price = 10**9 * (units / (emission / 10**9));
				ewma = ewma == 0 ? price : (3 * price + 2 * ewma) / 5; // apha = 0.6
			}
            if (remainingSupply > emission) {
                remainingSupply -= emission;
            }
            else {
                remainingSupply = 0;
            }
            if (currentAuction >= auctionsPerEra) {
                currentEra += 1;
                currentAuction = 0;
                nextEraTime = _now + secondsPerAuction * auctionsPerEra;
                emission = getNextEraEmission();
                mapEra_Emission[currentEra] = emission;
                emit NewEra(currentEra, emission, nextEraTime, totalContributed);
            }
            currentAuction += 1;
            nextAuctionTime = _now + secondsPerAuction;
            if (remainingSupply < emission) {
                // final auction
                emission = remainingSupply;
            }
            mapEraAuction_EmissionRemaining[currentEra][currentAuction] = emission;

            emit NewAuction(currentEra, currentAuction, nextAuctionTime, units, members, ewma);
        }
    }

    function getImpliedPriceEWMA(bool includeCurrentEra) public view returns (uint) {
        if (ewma == 0 || includeCurrentEra) {
            uint price = 10**9 * (mapEraAuction_Units[currentEra][currentAuction] / (emission / 10**9));
			return ewma == 0 ? price : (3 * price + 2 * ewma) / 5; // apha = 0.6
        }
        else {
            return ewma;
        }
    }

    function updateEmission() external {
        _updateEmission();
    }

    function getNextEraEmission() public view returns (uint) {
        if (emissionDecayRate == 1000) {
            return emission;
        }
        else {
            // decays only on first auction of this next era
            return emission * emissionDecayRate / 1000;
        }
    }

    function getAuctionEmission() public view returns (uint) {
        return emission;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }
}

contract Auction is BasicAuction {
    constructor(IERC20 _mainToken, IERC721 _nft)
        BasicAuction(
            _mainToken,
            _nft,

            7 * 86400, // secondsPerAuction

            52, // auctionsPerEra
            5,  // firstPublicAuction

            12_499_968_000000000000000000, // totalSupply for entire sale period
                80_128_000000000000000000, // initial auction emission = totalSupply / 3 / 52

            1_000, // decay rate per era

            payable(address(0x03Df4ADDfB568b338f6a0266f30458045bbEFbF2)))
    {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}