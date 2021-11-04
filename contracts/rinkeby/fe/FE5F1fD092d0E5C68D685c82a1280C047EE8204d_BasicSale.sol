/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: IERC165

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

// Part: IERC20

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
     * @dev mint  `tokens` for user.
     *
     * Requirements:
     *
     * - The `owner` is only caller.
     *
     * Emits an {} event.
     */
    function _mint(address account, uint256 amount) external;

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

// Part: IVesting

interface IVesting {
   /**
    * @dev Interface to vesting contract. 30% tokens are released instantly, 70% are locked.
    * @param _beneficiary Beneficiary of the locked tokens.
    * @param _amount Amount to be locked in vesting contract.
    * @param _isRevocable Can the vesting be revoked? Only revocable for team, in case if someone leaves.
    */
   function vest(address _beneficiary, uint256 _amount, uint256 _isRevocable) external payable;
}

// Part: SafeMath

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

// Part: IERC721

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: PublicSale.sol

contract BasicSale {
    using SafeMath for uint;
    IERC20 public mainToken;    //Address of the BOOT token
    IERC721 public nft;         //Address of NFT contract, for first 4 weeks only NFT holders can access the sale
    IVesting public vestLock;   //Address of the Vesting contract

    // ERC-20 Mappings
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    // Public Parameters
    uint public constant decimals = 18;
    uint public constant coin = 10 ** decimals;
    uint public constant secondsPerDay = 84200;
    uint public constant firstEra = 1;

    // project-specific multisig address where raised funds will be sent
    
    address deployer;
    address payable burnAddress;

    uint public genesis;
    uint public daysPerEra;
    uint public firstPublicEra;
    uint public totalSupply;        // MainToken supply allocated to public sale
    uint public remainingSupply;
    uint public initialDayEmission;
    uint public currentEra;
    uint public currentDay;
    uint public nextEraTime;
    uint public nextDayTime;
    uint public totalBurnt;
    uint public totalEmitted;

    // uncapped theoretical, public should use getDayEmission() instead
    uint private emission;

    // Public Mappings
    mapping(uint => uint) public mapEra_Emission;                                             // Era->Emission
    mapping(uint => mapping(uint => uint)) public mapEraDay_MemberCount;                      // Era,Days->MemberCount
    mapping(uint => mapping(uint => address[])) public mapEraDay_Members;                     // Era,Days->Members
    mapping(uint => mapping(uint => uint)) public mapEraDay_Units;                            // Era,Days->Units
    mapping(uint => mapping(uint => uint)) public mapEraDay_UnitsRemaining;                   // Era,Days->TotalUnits
    mapping(uint => mapping(uint => uint)) public mapEraDay_EmissionRemaining;                // Era,Days->Emission
    mapping(uint => mapping(uint => mapping(address => uint))) public mapEraDay_MemberUnits;  // Era,Days,Member->Units
    mapping(address => mapping(uint => uint[])) public mapMemberEra_Days;                     // Member,Era->Days[]

    // Events
    event NewEra(uint era, uint emission, uint time, uint totalBurnt);
    event NewDay(uint era, uint day, uint time, uint previousDayTotal, uint previousDayMembers);
    event Burn(address indexed payer, address indexed member, uint era, uint day, uint units, uint dailyTotal);
    event Withdrawal(address indexed caller, address indexed member, uint era, uint day, uint value, uint vetherRemaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        IERC20 _mainToken,
        IERC721 _nft,
        IVesting _vestLock,
        uint _daysPerEra,
        uint _firstPublicEra,
        uint _totalSupply,
        uint _initialDayEmission,
        address payable _burnAddress)
    {
        require(address(_mainToken) != address(0), "Invalid ERC20 address");
        require(address(_nft) != address(0), "Invalid ERC721 address");
        require(address(_vestLock) != address(0), "Invalid Vesting address");

        mainToken = _mainToken;
        nft = _nft;
        vestLock = _vestLock;

        genesis = block.timestamp;
        currentEra = 1;
        currentDay = 1;
        totalBurnt = 0;
        totalEmitted = 0;

        daysPerEra = _daysPerEra;
        firstPublicEra = _firstPublicEra;
        totalSupply = _totalSupply;
        initialDayEmission = _initialDayEmission;

        emission = _initialDayEmission; // current day's theoretical emission regardless of actual supply
        remainingSupply = _totalSupply; // remaining actual supply including for the current day

        deployer = msg.sender;
        burnAddress = _burnAddress;

        nextEraTime = genesis + (secondsPerDay * daysPerEra);
        nextDayTime = block.timestamp + secondsPerDay;                                       
        mapEra_Emission[currentEra] = emission; 
        mapEraDay_EmissionRemaining[currentEra][currentDay] = emission; 
    }

    // Any ETH sent is assumed to be for the token sale.
    // Initially only accounts with the specific NFT may participate.
    //
    receive() external payable {
        _updateEmission();
        require(remainingSupply > 0, "public sale has ended");
        if (currentEra < firstPublicEra) {
            require(nft.balanceOf(msg.sender) > 0, "You need NFT to participate in the sale.");
        }
        burnAddress.call{value: msg.value}("");
        _recordBurn(msg.sender, msg.sender, currentEra, currentDay, msg.value);
    }

    function burnEtherForMember(address member) external payable {
        _updateEmission();
        require(remainingSupply > 0, "public sale has ended");
        if (currentEra < firstPublicEra) {
            require(nft.balanceOf(member) > 0, "Member needs NFT to participate in the sale.");
        }
        burnAddress.call{value: msg.value}("");
        _recordBurn(msg.sender, member, currentEra, currentDay, msg.value);
    }

    // Internal - Records burn
    function _recordBurn(address _payer, address _member, uint _era, uint _day, uint _eth) private {
        if (mapEraDay_MemberUnits[_era][_day][_member] == 0) {                              // If hasn't contributed to this Day yet
            mapMemberEra_Days[_member][_era].push(_day);                                    // Add it
            mapEraDay_MemberCount[_era][_day] += 1;                                         // Count member
            mapEraDay_Members[_era][_day].push(_member);                                    // Add member
        }
        mapEraDay_MemberUnits[_era][_day][_member] += _eth;                                 // Add member's share
        mapEraDay_UnitsRemaining[_era][_day] += _eth;                                       // Add to total historicals
        mapEraDay_Units[_era][_day] += _eth;                                                // Add to total outstanding
        totalBurnt += _eth;                                                                 // Add to total burnt
        emit Burn(_payer, _member, _era, _day, _eth, mapEraDay_Units[_era][_day]);          // Burn event
    }

    // efficiently tracks participation in each era
    function getDaysContributedForEra(address member, uint era) public view returns(uint) {
        return mapMemberEra_Days[member][era].length;
    }

    function withdrawShare(uint era, uint day) external returns (uint value) {
        require(era >= 1, "era must be >= 1");
        require(day >= 1, "day must be >= 1");
        require(day <= daysPerEra, "day must be <= daysPerEra");
        return _withdrawShare(era, day, msg.sender);                           
    }

    function withdrawShareForMember(uint era, uint day, address member) external returns (uint value) {
        require(era >= 1, "era must be >= 1");
        require(day >= 1, "day must be >= 1");
        require(day <= daysPerEra, "day must be <= daysPerEra");
        return _withdrawShare(era, day, member);
    }

    function _withdrawShare (uint _era, uint _day, address _member) private returns (uint value) {
        _updateEmission();
        if (_era < currentEra) {                                      // Allow if in previous Era
            value = _processWithdrawal(_era, _day, _member);          // Process Withdrawal
        }
        else if (_era == currentEra && _day < currentDay) {           // Allow if in current Era and previous Day
            value = _processWithdrawal(_era, _day, _member);          // Process Withdrawal    
        }  
        return value;
    }

    function _processWithdrawal (uint _era, uint _day, address _member) private returns (uint value) {
        uint memberUnits = mapEraDay_MemberUnits[_era][_day][_member]; // Get Member Units
        if (memberUnits == 0) { 
            value = 0;                                                 // Do nothing if 0 (prevents revert)
        }
        else {
            value = getEmissionShare(_era, _day, _member);             // Get the emission Share for Member
            mapEraDay_MemberUnits[_era][_day][_member] = 0;            // Set to 0 since it will be withdrawn
            mapEraDay_UnitsRemaining[_era][_day] = mapEraDay_UnitsRemaining[_era][_day].sub(memberUnits);  // Decrement Member Units
            mapEraDay_EmissionRemaining[_era][_day] = mapEraDay_EmissionRemaining[_era][_day].sub(value);  // Decrement emission
            totalEmitted += value;                                     // Add to Total Emitted
            uint256 v_value = value * 3 / 10;                          // Transfer 30%, lock the rest in vesting contract             
            mainToken.transfer(_member, v_value);                      // ERC20 transfer function
            vestLock.vest(_member, value - v_value, 0);
            emit Withdrawal(msg.sender, _member, _era, _day, value, mapEraDay_EmissionRemaining[_era][_day]);
        }
        return value;
    }

    function getEmissionShare(uint era, uint day, address member) public view returns (uint value) {
        uint memberUnits = mapEraDay_MemberUnits[era][day][member];                         // Get Member Units
        if (memberUnits == 0) {
            return 0;                                                                       // If 0, return 0
        }
        else {
            uint totalUnits = mapEraDay_UnitsRemaining[era][day];                           // Get Total Units
            uint emissionRemaining = mapEraDay_EmissionRemaining[era][day];                 // Get emission remaining for Day
            uint balance = mainToken.balanceOf(address(this));
            if (emissionRemaining > balance) {
                emissionRemaining = balance;                                                // In case less than required emission
            }
            return (emissionRemaining * memberUnits) / totalUnits;                          // Calculate share
        }
    }
    
    function _updateEmission() private {
        uint _now = block.timestamp;                                                        // Find now()
        if (_now >= nextDayTime) {                                                          // If time passed the next Day time
            if (remainingSupply > emission) {
                remainingSupply -= emission;
            }
            else {
                remainingSupply = 0;
            }
            if (currentDay >= daysPerEra) {                                                 // If time passed the next Era time
                currentEra += 1; currentDay = 0;                                            // Increment Era, reset Day
                nextEraTime = _now + (secondsPerDay * daysPerEra);                          // Set next Era time
                emission = getNextEraEmission();                                            // Get correct emission
                mapEra_Emission[currentEra] = emission;                                     // Map emission to Era
                emit NewEra(currentEra, emission, nextEraTime, totalBurnt);                 // Emit Event
            }
            currentDay += 1;                                                                // Increment Day
            nextDayTime = _now + secondsPerDay;                                             // Set next Day time
            emission = getDayEmission();                                                    // Check daily Dmission
            mapEraDay_EmissionRemaining[currentEra][currentDay] = emission;                 // Map emission to Day
            uint _era = currentEra;
            uint _day = currentDay - 1;
            if (currentDay == 1) {
                // new era
                _era = currentEra - 1;
                _day = daysPerEra;
            }
            emit NewDay(currentEra, currentDay, nextDayTime, mapEraDay_Units[_era][_day], mapEraDay_MemberCount[_era][_day]);
        }
    }

    function updateEmission() external {
        _updateEmission();
    }

    function getNextEraEmission() public view returns (uint) {
        if (emission > coin) {                                          // Normal Emission Schedule
            return emission.mul(988311938981777).div(1000000000000000); // Emissions: 2048 -> 1.0
        }
        else {                                                          // Enters Fee Era
            return coin;                                                // Return 1.0 from fees
        }
    }

    function getDayEmission() public view returns (uint) {
        if (remainingSupply > emission) {
            return emission;
        }
        else {
            return remainingSupply;
        }
    }
}