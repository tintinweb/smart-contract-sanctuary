// contracts/DanceOff.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IHgh.sol";
import "./IMaticMike.sol";

contract DanceOff is VRFConsumerBase, Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _rumbleId;
    Counters.Counter private _pvpId;
    Counters.Counter private _challengeId;

    struct RollInfo{
        uint256 tokenId;
        address holder;
        uint256 roll;
    }

    struct BattleType{
        uint8 battleType;
        uint256 battleId;
        uint256 tokenId;
        uint8 juicedUp;
        uint256 wager;
    }

    struct Winner{
        uint256 tokenId;
        uint8 placement;
        uint256 rumbleId;
        uint256 payout;
        address holder;
    }

    struct Leaderboards{
        uint256[] firstP;
        uint256[] secondP;
        uint256[] thirdP;
    }

    uint256[] firstPlacements;
    uint256[] secondPlacements;
    uint256[] thirdPlacements;
    uint256[] noPlacements;

    // Track participants
    mapping(uint256 => RollInfo[]) rumbleIdToRolls;
    mapping(bytes32 => BattleType) responseIdToBattle;
    
    mapping(uint256 => bool) battleIsComplete;
    mapping(uint256 => Winner[]) battleIdToWinners;
    mapping(uint256 => uint256) royaleTimeTrigger;
    mapping(uint256 => uint8) royaleParticipants;
    mapping(uint256 => uint8) royaleProcessedLink;
    mapping(uint256 => uint256) royalePot;

    mapping(uint256 => mapping(uint256 => bool)) tokenToRumble;
    
    // analytical stuff
    mapping(uint256 => uint256[]) tokenToRumblesEntered;
    mapping(uint256 => Winner[]) tokenToWinner;
    mapping(uint256 => uint256[]) rumbleIdParticipants;

    mapping(address => Winner[]) addressToWinner;
    mapping(address => uint256[]) addressToRumblesEntered;

    // 
    uint256 wagerMulti = 1000000000000000000;
    uint256 currentPrice = 1000000000000000000;
    uint8 rumbleSize = 50;
    uint8 minimumSize = 20;
    uint256 maxTime = 1800; // 30 minute trigger
    uint8 maxJuice = 5;

    address hghAddress;
    address mmAddress;

    bytes32 private keyHash;
    uint256 private fee;

    Leaderboards leaders;

    bool public active = false;

    // Mainnet
    // LINK Token	0xb0897686c545045aFc77CF20eC7A532E3120E0F1
    // VRF Coordinator	0x3d2341ADb2D31f1c5530cDC622016af293177AE0
    // Key Hash	0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
    // Fee	0.0001 LINK

    // Mumbai
    // LINK Token	0x326C977E6efc84E512bB9C30f76E30c160eD06FB
    // VRF Coordinator	0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
    // Key Hash	0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
    // Fee	0.0001 LINK

    constructor() 
        VRFConsumerBase(0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 0xb0897686c545045aFc77CF20eC7A532E3120E0F1)
    {
        // Chainlink Info
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK
        royaleTimeTrigger[_rumbleId.current()] = block.timestamp;
    }

    // owner functions set everything
    function setTimeTriggerNow() public onlyOwner{
        royaleTimeTrigger[_rumbleId.current()] = block.timestamp;
    }

    function setActive(bool _active) public onlyOwner{
        active = _active;
    }

    function setAddress(address _hghAddress, address _mmAddress) public onlyOwner{
        hghAddress = _hghAddress;
        mmAddress = _mmAddress;
    }

    function setPrice(uint256 _price) public onlyOwner{
        currentPrice = _price;
    }

    function setRumbleSize(uint8 _size) public onlyOwner{
        rumbleSize = _size;
    }

    function setMinSize(uint8 _size) public onlyOwner{
        minimumSize = _size;
    }

    function setMaxTime(uint256 _time) public onlyOwner{
        maxTime = _time;
    }

    function withdrawHghIfStuck() public onlyOwner{
        uint256 balance = IHgh(hghAddress).balanceOf(address(this));
        IHgh(hghAddress).transfer(msg.sender, balance);
    }

    function forceStart(uint256 rumbleId) public onlyOwner{
        beginDance(rumbleId);
    }

    function setLinkFee(uint256 _fee) public onlyOwner{
        fee = _fee;
    }

    function setMaxJuice(uint8 _maxJuice)public onlyOwner{
        maxJuice = _maxJuice;
    }

    // end owner functions

    // // analytical stuff
    // mapping(uint256 => uint256[]) tokenToRumblesEntered;
    function getMaxJuice() public view returns (uint8){
        return maxJuice;
    }

    function getCurrentRumble() public view returns (uint256){
        return _rumbleId.current();
    }

    function getCurrentPot() public view returns (uint256){
        return royalePot[_rumbleId.current()];
    }

    function getCurrentEntries() public view returns (uint8){
        return royaleParticipants[_rumbleId.current()];
    }
    
    function getTimeTrigger() public view returns (uint256){
        return royaleTimeTrigger[_rumbleId.current()];
    }

    function isComplete(uint256 rumbleId) public view returns (bool){
        return battleIsComplete[rumbleId];
    }

    function getRumblesEntered(uint256 _tokenId) public view returns (uint256[] memory){
        return tokenToRumblesEntered[_tokenId];
    }

    function getPlacementsByToken(uint256 _tokenId) public view returns (Winner[] memory){
        return tokenToWinner[_tokenId];
    }

    function getPlacementsByAddress(address _address) public view returns (Winner[] memory){
        return addressToWinner[_address];
    }

    function getRumblesEnteredByAddress(address _address) public view returns (uint256[] memory){
        return addressToRumblesEntered[_address];
    }

    function getPlacementsByRumble(uint256 rumbleId) public view returns (Winner[] memory){
        return battleIdToWinners[rumbleId];
    }

    function getEntriesByRumble(uint256 rumbleId) public view returns (uint256[] memory){
        return rumbleIdParticipants[rumbleId];
    }

    function getLeaderboards() public view returns (Leaderboards memory){
        return leaders;
    }

    function getFirstPlace() public view returns (uint256[] memory){
        return firstPlacements;
    }

    function getSecondPlace() public view returns (uint256[] memory){
        return secondPlacements;
    }

    function getThirdPlace() public view returns (uint256[] memory){
        return thirdPlacements;
    }

    // enter battle royale
    function enterRoyale(uint256 _tokenId, uint8 _hghJuice) public returns (uint256){
        require(active, "Dance Royale not currently active");
        require((_hghJuice * wagerMulti) % wagerMulti == 0, "HGH Amount cannot be a decimal");
        require(_hghJuice <= maxJuice, "Over the maximum juice amount");
        require(IHgh(hghAddress).balanceOf(msg.sender) >= (_hghJuice * wagerMulti) + currentPrice, "Not enough HGH in wallet balance");
        
        // check in gym as well 
        require(IMaticMike(mmAddress).ownerOf(_tokenId) == msg.sender || IHgh(hghAddress).getStaker(_tokenId) == msg.sender, "Not the owner of token");
        require(royaleParticipants[_rumbleId.current()] < rumbleSize && !battleIsComplete[_rumbleId.current()], "Royale trigger currently in progress. Try again in a minute");
        
        // require that they are not already entered in the competition...
        require(!tokenToRumble[_tokenId][_rumbleId.current()], "Already entered in competition");

        // if new rumble populate analytics from previous rumble
        if(_rumbleId.current() != 0 && royaleParticipants[_rumbleId.current()] == 0){
            populateWinners(_rumbleId.current() - 1);
        }

        // burn the juiced up amount
        IHgh(hghAddress).burnFrom(msg.sender, _hghJuice * wagerMulti);

        // transfer 1 HGH to contract
        IHgh(hghAddress).transferFrom(msg.sender, address(this), currentPrice);

        // begin royale entry
        royaleParticipants[_rumbleId.current()]++;
        royalePot[_rumbleId.current()] = royalePot[_rumbleId.current()] + wagerMulti;
        tokenToRumble[_tokenId][_rumbleId.current()] = true;
        
        bytes32 requestId = requestRandomness(keyHash, fee);

        responseIdToBattle[requestId] = BattleType(
            1,
            _rumbleId.current(),
            _tokenId,
            _hghJuice,
            wagerMulti
        );

        rumbleIdParticipants[_rumbleId.current()].push(_tokenId);
        tokenToRumblesEntered[_tokenId].push(_rumbleId.current());
        addressToRumblesEntered[msg.sender].push(_rumbleId.current());

        return _rumbleId.current();
    }

    // fulfill chainlink VRF randomness, and run roll logic
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 rumbleId = responseIdToBattle[requestId].battleId;
        uint256 powerup = 0;

        if(responseIdToBattle[requestId].juicedUp > 0){
            powerup = (randomness % (responseIdToBattle[requestId].juicedUp * 9)) + responseIdToBattle[requestId].juicedUp;
        }

        uint powerlevel = IMaticMike(mmAddress).getPowerLevel(responseIdToBattle[requestId].tokenId) + powerup;
        address tokenHolder;

        // check if in gym and assign accordingly
        if(IMaticMike(mmAddress).ownerOf(responseIdToBattle[requestId].tokenId) != hghAddress){
            tokenHolder = IMaticMike(mmAddress).ownerOf(responseIdToBattle[requestId].tokenId);
        }
        else{
            tokenHolder = IHgh(hghAddress).getStaker(responseIdToBattle[requestId].tokenId);
        }
         

        uint256 roll = randomness % powerlevel;

        rumbleIdToRolls[rumbleId].push(
            RollInfo(
                responseIdToBattle[requestId].tokenId,
                tokenHolder,
                roll
            )
        );

        royaleProcessedLink[rumbleId]++;

        if(royaleProcessedLink[rumbleId] == royaleParticipants[rumbleId]){
            if(royaleParticipants[rumbleId] >= rumbleSize){
                beginDance(rumbleId);
            }
            else if(royaleParticipants[rumbleId] >= minimumSize && block.timestamp - royaleTimeTrigger[rumbleId] >= maxTime){
                beginDance(rumbleId);
            }
        }
    }

    function beginDance(uint256 rumbleId) internal{
        require(!battleIsComplete[rumbleId], "Battle already completed");

        RollInfo memory fpRoll;
        RollInfo memory spRoll;
        RollInfo memory tpRoll;

        // we should sort all the entries and create an array of structs from lowest to highest
        for(uint16 i=0; i<rumbleIdToRolls[rumbleId].length; i++){
            if(rumbleIdToRolls[rumbleId][i].roll > fpRoll.roll){
                tpRoll = spRoll;
                spRoll = fpRoll;
                fpRoll = rumbleIdToRolls[rumbleId][i];
            }
            else if(rumbleIdToRolls[rumbleId][i].roll == fpRoll.roll){
                tpRoll = spRoll;

                if(coinFlip(rumbleIdToRolls[rumbleId][i].tokenId, rumbleIdToRolls[rumbleId][i].holder, i) > 0){
                    spRoll = fpRoll;
                    fpRoll = rumbleIdToRolls[rumbleId][i];
                }
                else{
                    spRoll = rumbleIdToRolls[rumbleId][i];
                }
            }
            else if(rumbleIdToRolls[rumbleId][i].roll > spRoll.roll){
                tpRoll = spRoll;
                spRoll = rumbleIdToRolls[rumbleId][i];
            }
            else if(rumbleIdToRolls[rumbleId][i].roll == spRoll.roll){
                if(coinFlip(rumbleIdToRolls[rumbleId][i].tokenId, rumbleIdToRolls[rumbleId][i].holder, i) > 0){
                    tpRoll = spRoll;
                    spRoll = rumbleIdToRolls[rumbleId][i];
                }
                else{
                    tpRoll = rumbleIdToRolls[rumbleId][i];
                }
            }
            else if(rumbleIdToRolls[rumbleId][i].roll > tpRoll.roll){
                tpRoll = rumbleIdToRolls[rumbleId][i];
            }
            else if(rumbleIdToRolls[rumbleId][i].roll == tpRoll.roll && coinFlip(rumbleIdToRolls[rumbleId][i].tokenId, rumbleIdToRolls[rumbleId][i].holder, i) > 0){
                tpRoll = rumbleIdToRolls[rumbleId][i];
            }
        }

        uint256 totalPot = royalePot[rumbleId];
        uint256 tpPayout = totalPot * 1/10;
        uint256 spPayout = totalPot * 2/10;
        uint256 fpPayout = totalPot * 7/10;


        // we should have a internal struct that saves the top 3 placements
        battleIdToWinners[rumbleId].push(
            Winner(
                fpRoll.tokenId,
                1,
                rumbleId,
                fpPayout,
                fpRoll.holder
            )
        );

        battleIdToWinners[rumbleId].push(
            Winner(
                spRoll.tokenId,
                2,
                rumbleId,
                spPayout,
                spRoll.holder
            )
        );

        battleIdToWinners[rumbleId].push(
            Winner(
                tpRoll.tokenId,
                3,
                rumbleId,
                tpPayout,
                tpRoll.holder
            )
        );

        // increase rumbleid
        battleIsComplete[rumbleId] = true;

        _rumbleId.increment();
        royaleTimeTrigger[_rumbleId.current()] = block.timestamp;
        
        // payout winners
        IHgh(hghAddress).transfer(tpRoll.holder, tpPayout);
        IHgh(hghAddress).transfer(spRoll.holder, spPayout);
        IHgh(hghAddress).transfer(fpRoll.holder, fpPayout);
    }

    function coinFlip(uint256 _t, address _a, uint16 _c) internal view returns (uint8){
        return uint8(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            _rumbleId.current()
                        )
                    )
                ) % 2
            );
    }


    // analytics stuff
    function populateWinners(uint256 rumbleId) internal{
        for(uint8 i=0; i<battleIdToWinners[rumbleId].length; i++){
            tokenToWinner[battleIdToWinners[rumbleId][i].tokenId].push(battleIdToWinners[rumbleId][i]);
            addressToWinner[battleIdToWinners[rumbleId][i].holder].push(battleIdToWinners[rumbleId][i]);
            
            if(battleIdToWinners[rumbleId][i].placement == 1){
                firstPlacements.push(battleIdToWinners[rumbleId][i].tokenId);
                leaders.firstP = firstPlacements;
            }
            else  if(battleIdToWinners[rumbleId][i].placement == 2){
                secondPlacements.push(battleIdToWinners[rumbleId][i].tokenId);
                leaders.secondP = secondPlacements;
            }
            else if(battleIdToWinners[rumbleId][i].placement == 3){
                thirdPlacements.push(battleIdToWinners[rumbleId][i].tokenId);
                leaders.thirdP = thirdPlacements;
            }
        }
    }
}

// contracts/IMaticMike.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface IMaticMike is IERC721Enumerable {    
    function withdrawnTokens(uint256 tokenId) external view returns (bool);
    function getPowerLevel(uint256 tokenId) external view returns (uint16);
}

// contracts/IHgh.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHgh is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function getStaker(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}