// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/ICryptoFoxesOriginsV2.sol";
import "./interfaces/ICryptoFoxesStakingV2.sol";
import "./interfaces/ICryptoFoxesCalculationV2.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./CryptoFoxesUtility.sol";

// @author: miinded.com

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                    ((((((((.                (((((                               //
//                    @@@@@@@@.                @@@@@                               //
//                    @@@&&&%%@@@              @@@&&@@@                            //
//                    @@@%%%@@#((@@@        @@@&&&&&%%%@@@                         //
//                    @@@(((%%,..(((@@&     @@@&&&%%///@@@                         //
//                 %@@(((@@@..   [email protected]@&     @@@%%%/////(((@@%                      //
//                 %@@///@@&        ///@@@@@%%%%%%((//////@@%                      //
//                 (%%///@@&        @@@/////(((@@@%%%%%///@@%                      //
//                 (%%///@@&     %%%(((///////////((@@@(((%%#                      //
//                 (%%///...  #%%/////////////////////////%%#                      //
//                 %@@///@@@@@#((/////////////////////////@@%                      //
//                 %@@///%%%%%(((////////((((((/////((((((%%#//                    //
//                 %@@///(((/////////////((((((/////((((((((#@@                    //
//               @@#((//////////////////////////////////////(%%                    //
//               @@#((//////////////&&&&&&&&&&&////////&&&&&&%%                    //
//               @@(/////////////&&&     (((   ////////(((  ,&&                    //
//            @@@((///////////(((&&&     ###   ///(((((###  ,&&%%%                 //
//            @@@/////......     (((///////////((#&&&&&&&&..,((%%%                 //
//            @@@((.                ..,//,.....     &&&     .//@@@                 //
//               @@#((...                      &&&&&...&&&     @@@                 //
//    @@@@@      @@#((                                       [email protected]@@                 //
// @@@..(%%        %@@%%%%%%.....                         ..*%%                    //
// (((../((***     /((///////////*************************/////                    //
//      ...%%%              @@&%%%%%%%%%%%%%%%%%%%%%@@@@@@%%#                      //
//         ...%%%        &&%##(((.................**@@@                            //
//            [email protected]@,     %%%/////...              ..(((@@@                         //
// ...        ///((&@@@@@////////%%%             .%%(((@@@              Miinded    //
// ...     ////////(((@@@/////(((%%%             .%%((((((%%#                      //
/////////////////////////////////////////////////////////////////////////////////////

contract CryptoFoxesStakingV2 is Ownable, CryptoFoxesUtility, ICryptoFoxesStakingV2, IERC721Receiver {

    uint32 constant HASH_SIGN_STAKING_V2 = 9248467;
    uint8 constant MIN_SLOT = 9;
    uint8 constant MAX_SLOT = 20;
    uint16 constant NULL = 65535;

    mapping(uint16 => Staking) public staked;
    mapping(uint16 => Origin) public origins;
    mapping(uint256 => bool) private signatures;
    mapping(address => uint16[]) public walletOwner;
    mapping(uint16 => uint16) private walletOwnerTokenIndex;

    IERC721 private cryptoFoxes;
    ICryptoFoxesOriginsV2 private cryptoFoxesOrigin;
    ICryptoFoxesCalculationV2 public calculationContract;

    constructor( address _cryptoFoxesOrigin,address _cryptoFoxesContract) {
        cryptoFoxesOrigin = ICryptoFoxesOriginsV2(_cryptoFoxesOrigin);
        cryptoFoxes = IERC721(_cryptoFoxesContract);
    }

    event EventStack(uint16 _tokenId, uint16 _tokenIdOrigin, address _owner);
    event EventUnstack(uint16 _tokenId, address _owner);
    event EventClaim(uint16 _tokenId, address _owner);
    event EventMove(uint16 _tokenId, uint16 _tokenIdOriginTo, address _owner);

    function initOrigins() public onlyOwner{
        for(uint16 i = 1; i <= 1000; i++){
            origins[i].maxSlots = MIN_SLOT;
        }
    }

    //////////////////////////////////////////////////
    //      STAKING                                 //
    //////////////////////////////////////////////////

    function stack(uint16[] memory _tokenIds, uint16 _tokenIdOrigin) public {
        require(!disablePublicFunctions, "Function disabled");
        _stack(_msgSender(), _tokenIds, _tokenIdOrigin);
    }
    function stackByContract(address _wallet, uint16[] memory _tokenIds, uint16 _tokenIdOrigin) public isFoxContract{
        _stack(_wallet, _tokenIds, _tokenIdOrigin);
    }
    function _stack(address _wallet, uint16[] memory _tokenIds, uint16 _tokenIdOrigin) private {

        require(cryptoFoxesOrigin.ownerOf(_tokenIdOrigin) != address(0), "CryptoFoxesStakingV2:stack origin not minted");
        require(_tokenIdOrigin >= 1 && _tokenIdOrigin <= 1000, "CryptoFoxesStakingV2:stack token out of range");

        if(origins[_tokenIdOrigin].maxSlots == 0){
            origins[_tokenIdOrigin].maxSlots = MIN_SLOT;
        }

        require(origins[_tokenIdOrigin].stacked.length + _tokenIds.length <= origins[_tokenIdOrigin].maxSlots, "CryptoFoxesStakingV2:stack no slots");

        for(uint16 i = 0; i < _tokenIds.length; i++){

            require(cryptoFoxes.ownerOf(_tokenIds[i]) == _wallet, "CryptoFoxesStakingV2:stack Not owner");

            staked[_tokenIds[i]].tokenId = _tokenIds[i];
            staked[_tokenIds[i]].owner = _wallet;
            staked[_tokenIds[i]].timestampV2 = uint64(block.timestamp);

            _stackAction(_tokenIds[i],_tokenIdOrigin);

            cryptoFoxes.safeTransferFrom(_wallet, address(this), _tokenIds[i]);

            walletOwnerTokenIndex[_tokenIds[i]] = uint16(walletOwner[_wallet].length);
            walletOwner[_wallet].push(_tokenIds[i]);

            emit EventStack(_tokenIds[i], _tokenIdOrigin, _wallet);
        }
    }

    function _stackAction(uint16 _tokenId, uint16 _tokenIdOrigin) private{
        staked[_tokenId].origin = _tokenIdOrigin;
        staked[_tokenId].slotIndex = uint8(origins[_tokenIdOrigin].stacked.length);
        origins[_tokenIdOrigin].stacked.push(_tokenId);
    }

    function unstack(uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) public {
        require(!disablePublicFunctions, "Function disabled");
        _unstack(_msgSender(), _tokenIds, _bonusSteak, _signatureId, _signature);
    }
    function unstackByContract(address _wallet, uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) public isFoxContract{
        _unstack(_wallet, _tokenIds, _bonusSteak, _signatureId, _signature);
    }
    function _unstack(address _wallet, uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) private {

        _claimRewardsV2(_wallet, _tokenIds, _bonusSteak, _signatureId, _signature);

        for(uint16 i = 0; i < _tokenIds.length; i++){

            require(isStaked(_tokenIds[i]) && staked[_tokenIds[i]].owner == _wallet, "CryptoFoxesStakingV2:unstack Not owner");

            uint16 tokenIdOrigin = getOriginByV2(_tokenIds[i]);
            _unstackAction(_tokenIds[i], tokenIdOrigin);

            staked[_tokenIds[i]].tokenId = NULL;

            cryptoFoxes.safeTransferFrom(address(this), _wallet, _tokenIds[i]);

            uint16 index = walletOwnerTokenIndex[_tokenIds[i]];
            uint16 last = uint16(walletOwner[_wallet].length - 1);

            if(index != last){
                walletOwner[_wallet][index] = walletOwner[_wallet][last];
                walletOwnerTokenIndex[ walletOwner[_wallet][last] ] = index;
            }
            walletOwner[_wallet].pop();

            emit EventUnstack(_tokenIds[i], _wallet);
        }
    }

    function _unstackAction(uint16 _tokenId, uint16 _tokenIdOrigin) private{
        uint8 slotIndex = staked[_tokenId].slotIndex;
        uint8 lastSlot = uint8(origins[_tokenIdOrigin].stacked.length - 1);

        if(slotIndex != lastSlot){
            origins[_tokenIdOrigin].stacked[slotIndex] = origins[_tokenIdOrigin].stacked[lastSlot];
            staked[ origins[_tokenIdOrigin].stacked[lastSlot] ].slotIndex = slotIndex;
        }

        origins[_tokenIdOrigin].stacked.pop();
    }

    function claimSignature(address _wallet, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) public pure returns(address){
        return ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(_wallet, _bonusSteak, _signatureId, HASH_SIGN_STAKING_V2)))), _signature);
    }

    function moveStack(uint16 _tokenId, uint16 _tokenIdOriginTo) public {
        require(!disablePublicFunctions, "Function disabled");
        _moveStack(_msgSender(), _tokenId, _tokenIdOriginTo);
    }
    function moveStackByContract(address _wallet, uint16 _tokenId, uint16 _tokenIdOriginTo) public isFoxContract {
        _moveStack(_wallet, _tokenId, _tokenIdOriginTo);
    }
    function _moveStack(address _wallet, uint16 _tokenId, uint16 _tokenIdOriginTo) private {

        require(isStaked(_tokenId), "CryptoFoxesStakingV2:moveStack Not owner");
        uint16 tokenIdOrigin = getOriginByV2(_tokenId);
        require(cryptoFoxesOrigin.ownerOf(tokenIdOrigin) == _wallet, "CryptoFoxesStakingV2:moveStack origin not owner");
        require(cryptoFoxesOrigin.ownerOf(_tokenIdOriginTo) != address(0), "CryptoFoxesStakingV2:moveStack originTo not minted");
        require(_tokenIdOriginTo >= 1 && _tokenIdOriginTo <= 1000, "CryptoFoxesStakingV2:moveStack tokenTo out of range");

        if(origins[_tokenIdOriginTo].maxSlots == 0){
            origins[_tokenIdOriginTo].maxSlots = MIN_SLOT;
        }

        require(origins[_tokenIdOriginTo].stacked.length < origins[_tokenIdOriginTo].maxSlots, "CryptoFoxesStakingV2:moveStack no slots");

        _unstackAction(_tokenId, tokenIdOrigin);
        _stackAction(_tokenId,_tokenIdOriginTo);

        calculationContract.claimMoveRewardsOrigin(address(this), _tokenId, _wallet);

        emit EventMove(_tokenId, _tokenIdOriginTo, _wallet);
    }

    //////////////////////////////////////////////////
    //      SLOTS                                   //
    //////////////////////////////////////////////////

    function unlockSlot(uint16 _tokenIdOrigin, uint8 _count) public override isFoxContractOrOwner {
        require(origins[_tokenIdOrigin].maxSlots + _count <= MAX_SLOT, "CryptoFoxesStakingV2:unlockSlot Max slot limit");
        if(origins[_tokenIdOrigin].maxSlots == 0){
            origins[_tokenIdOrigin].maxSlots = MIN_SLOT;
        }
        origins[_tokenIdOrigin].maxSlots += _count;
    }

    //////////////////////////////////////////////////
    //      REWARDS                                 //
    //////////////////////////////////////////////////

    function calculateRewardsV2(uint16[] memory _tokenIds, uint256 _currentTimestamp) public view returns (uint256) {
        return calculationContract.calculationRewardsV2(address(this), _tokenIds, _currentTimestamp);
    }

    function claimRewardsV2(uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) public {
        require(!disablePublicFunctions, "Function disabled");
        _claimRewardsV2(_msgSender(), _tokenIds, _bonusSteak, _signatureId, _signature);
    }
    function claimRewardsV2ByContract(address _wallet, uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) public isFoxContract {
        _claimRewardsV2(_wallet, _tokenIds, _bonusSteak, _signatureId, _signature);
    }
    function _claimRewardsV2(address _wallet, uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) private {

        require(_tokenIds.length > 0 && !isPaused(), "Tokens empty");

        if(_bonusSteak > 0){
            require(signatures[_signatureId] == false, "CryptoFoxesStakingV2:claimRewardsV2 signature used");
            signatures[_signatureId] = true;
            require(claimSignature(_wallet, _bonusSteak, _signatureId, _signature) == owner(), "CryptoFoxesStakingV2:claimRewardsV2 signature fail"); // 6k
            _addRewards(_wallet, _bonusSteak);
        }

        for(uint16 i = 0; i < _tokenIds.length; i++){
            require(isStaked(_tokenIds[i]) && staked[_tokenIds[i]].owner == _wallet, "Bad owner");

            for (uint16 j = 0; j < i; j++) {
                require(_tokenIds[j] != _tokenIds[i], "Duplicate id");
            }
        }

        calculationContract.claimRewardsV2(address(this), _tokenIds, _wallet);

        for(uint16 i = 0; i < _tokenIds.length; i++){
            staked[_tokenIds[i]].timestampV2 = uint64(block.timestamp);

            emit EventClaim(_tokenIds[i], _wallet);
        }

    }

    //////////////////////////////////////////////////
    //      GETTERS                                 //
    //////////////////////////////////////////////////

    function getOriginByV2(uint16 _tokenId) public view override returns(uint16){
        return staked[_tokenId].origin;
    }
    function getStakingTokenV2(uint16 _tokenId) public override view returns(uint256){
        return uint256(staked[_tokenId].timestampV2);
    }
    function totalSupply() public view returns(uint16){
        uint16 totalStaked = 0;
        for(uint16 i = 1; i <= 1000; i++){
            totalStaked += uint16(origins[i].stacked.length);
        }
        return totalStaked;
    }
    function getOriginMaxSlot(uint16 _tokenIdOrigin) public view override returns(uint8){
        return origins[_tokenIdOrigin].maxSlots;
    }
    function getV2ByOrigin(uint16 _tokenIdOrigin) public override view returns(Staking[] memory){
        Staking[] memory tokenIds = new Staking[](origins[_tokenIdOrigin].stacked.length);
        for(uint16 i = 0; i < origins[_tokenIdOrigin].stacked.length; i++){
            tokenIds[i] = staked[ origins[_tokenIdOrigin].stacked[i] ];
        }
        return tokenIds;
    }
    function walletOfOwner(address _wallet) public view returns(Staking[] memory){
        Staking[] memory tokenIds = new Staking[](walletOwner[_wallet].length);
        for(uint16 i = 0; i < walletOwner[_wallet].length; i++){
            tokenIds[i] = staked[ walletOwner[_wallet][i] ];
        }
        return tokenIds;
    }

    //////////////////////////////////////////////////
    //      SETTERS                                 //
    //////////////////////////////////////////////////

    function setCryptoFoxes(address _contract) public onlyOwner{
        if(address(cryptoFoxes) != address(0)) {
            setAllowedContract(address(cryptoFoxes), false);
        }
        cryptoFoxes = IERC721(_contract);
        setAllowedContract(_contract, true);

    }
    function setCryptoFoxesOrigin(address _contract) public onlyOwner{
        if(address(cryptoFoxesOrigin) != address(0)) {
            setAllowedContract(address(cryptoFoxesOrigin), false);
        }
        cryptoFoxesOrigin = ICryptoFoxesOriginsV2(_contract);
        setAllowedContract(_contract, true);

    }
    function setCalculationContract(address _contract) public isFoxContractOrOwner {
        if(address(calculationContract) != address(0)) {
            setAllowedContract(address(calculationContract), false);
        }

        calculationContract = ICryptoFoxesCalculationV2(_contract);
        setAllowedContract(_contract, true);
    }

    //////////////////////////////////////////////////
    //      TESTERS                                 //
    //////////////////////////////////////////////////

    function isStaked(uint16 _tokenId) public view returns(bool){
        return staked[_tokenId].tokenId != NULL;
    }

    //////////////////////////////////////////////////
    //      OTHER                                   //
    //////////////////////////////////////////////////

    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns(bytes4){
        return this.onERC721Received.selector /*^ this.transfer.selector*/;
    }
    function _currentTime(uint256 _currentTimestamp) public override(ICryptoFoxesStakingV2, CryptoFoxesUtility) view returns (uint256) {
        return super._currentTime(_currentTimestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesSteak {
    function addRewards(address _to, uint256 _amount) external;
    function withdrawRewards(address _to) external;
    function isPaused() external view returns(bool);
    function dateEndRewards() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com
import "./ICryptoFoxesStakingStruct.sol";

interface ICryptoFoxesStakingV2 is ICryptoFoxesStakingStruct  {
    function getOriginMaxSlot(uint16 _tokenIdOrigin) external view returns(uint8);
    function getStakingTokenV2(uint16 _tokenId) external view returns(uint256);
    function getV2ByOrigin(uint16 _tokenIdOrigin) external view returns(Staking[] memory);
    function getOriginByV2(uint16 _tokenId) external view returns(uint16);
    function unlockSlot(uint16 _tokenId, uint8 _count) external;
    function _currentTime(uint256 _currentTimestamp) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesStakingStruct {

    struct Staking {
        uint8 slotIndex;
        uint16 tokenId;
        uint16 origin;
        uint64 timestampV2;
        address owner;
    }

    struct Origin{
        uint8 maxSlots;
        uint16[] stacked;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com
import "./ICryptoFoxesOrigins.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICryptoFoxesOriginsV2 is ICryptoFoxesOrigins, IERC721  {
    function walletOfOwner(address _owner) external view returns(uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesOrigins {
    function getStackingToken(uint256 tokenId) external view returns(uint256);
    function _currentTime(uint256 _currentTimestamp) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesCalculationV2 {
    function calculationRewardsV2(address _contract, uint16[] calldata _tokenIds, uint256 _currentTimestamp) external view returns(uint256);
    function claimRewardsV2(address _contract, uint16[] calldata _tokenIds, address _owner) external;
    function claimMoveRewardsOrigin(address _contract, uint16 _tokenId, address _ownerOrigin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICryptoFoxesSteak.sol";
import "./CryptoFoxesAllowed.sol";

// @author: miinded.com

abstract contract CryptoFoxesUtility is Ownable,CryptoFoxesAllowed, ICryptoFoxesSteak {
    using SafeMath for uint256;

    uint256 public endRewards = 0;
    ICryptoFoxesSteak public cryptofoxesSteak;
    bool public disablePublicFunctions = false;

    function setCryptoFoxesSteak(address _contract) public onlyOwner {
        cryptofoxesSteak = ICryptoFoxesSteak(_contract);
        setAllowedContract(_contract, true);
        synchroEndRewards();
    }
    function _addRewards(address _to, uint256 _amount) internal {
        cryptofoxesSteak.addRewards(_to, _amount);
    }
    function addRewards(address _to, uint256 _amount) public override isFoxContract  {
        _addRewards(_to, _amount);
    }
    function withdrawRewards(address _to) public override isFoxContract {
        cryptofoxesSteak.withdrawRewards(_to);
    }
    function _withdrawRewards(address _to) internal {
        cryptofoxesSteak.withdrawRewards(_to);
    }
    function isPaused() public view override returns(bool){
        return cryptofoxesSteak.isPaused();
    }
    function synchroEndRewards() public {
        endRewards = cryptofoxesSteak.dateEndRewards();
    }
    function dateEndRewards() public view override returns(uint256){
        require(endRewards > 0, "End Rewards error");
        return endRewards;
    }
    function _currentTime(uint256 _currentTimestamp) public view virtual returns (uint256) {
        return min(_currentTimestamp, dateEndRewards());
    }
    function min(uint256 a, uint256 b) public pure returns (uint256){
        return a > b ? b : a;
    }
    function max(uint256 a, uint256 b) public pure returns (uint256){
        return a > b ? a : b;
    }
    function setDisablePublicFunctions(bool _toggle) public isFoxContractOrOwner{
        disablePublicFunctions = _toggle;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICryptoFoxesSteak.sol";

// @author: miinded.com

abstract contract CryptoFoxesAllowed is Ownable {

    mapping (address => bool) public allowedContracts;

    modifier isFoxContract() {
        require(allowedContracts[_msgSender()] == true, "Not allowed");
        _;
    }
    
    modifier isFoxContractOrOwner() {
        require(allowedContracts[_msgSender()] == true || _msgSender() == owner(), "Not allowed");
        _;
    }

    function setAllowedContract(address _contract, bool _allowed) public onlyOwner {
        allowedContracts[_contract] = _allowed;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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