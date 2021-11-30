/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/utils/Context.sol

/*
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

// File: @openzeppelin/contracts/security/Pausable.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: contracts/DCSPresaleVendor.sol

contract DCSPresaleVendor is Ownable, Pausable
{
    //========================
    // LIBS
    //========================

    using Address for address payable;

    //========================
    // STRUCTS
    //========================

    struct UserInfo
    {
        bool whitelisted;
        uint256 bought;
        uint256 firstBuyTime;
    }

    //========================
    // CONSTANTS
    //========================

    uint256 public constant WHITELIST_PRESALE_DURATION = 24 hours; //1 days;

    //========================
    // ATTRIBUTES
    //========================

    uint256 public immutable pricePerUnit; //BNB per Unit
    uint256 public forSale; //max unit for sale
    uint256 public sold; //sold units
    address payable public immutable receiver; //address to send BNB too    

    uint256 public saleStartTime; //start time
    uint256 public immutable whitelistUnitsPerUser = 10; //whitlist phase maximum

    mapping(address => UserInfo) userMap; //users
    address[] public buyers; //buyer list

    //========================
    // EVENTS
    //========================

    event UserBuy(address indexed _user, uint256 _amount);

    //========================
    // CREATE
    //========================

    constructor(
        address payable _receiver,
        uint256 _pricePerUnit,
        uint256 _forSale,
        uint256 _startTime
    )
    {
        saleStartTime = _startTime;
        receiver = _receiver;
        pricePerUnit = _pricePerUnit;
        forSale = _forSale;

        initWhitelist();
    }

    function initWhitelist() private
    {
        address[128] memory list = [
            0xA24bd512D81ab7a949267f14e3085702f2848931
            ,0x459A16C988f1959Aa040bB2FB8cBA20B0891dB0a
            ,0xdd0b51ED9691E547793D7c35CADd65a02FB97604
            ,0xe8530CC7575C8aBb3C3F8d8Cc00444D99bc13A21
            ,0x97b50A3CA53a2256E1a24f0A3C559De8B427B2A4
            ,0x6c1cc9c0f32980Ead12373e5312EE046D00664bE
            ,0x0b29702F2362370a2e9dC5ea9E444535f8866353
            ,0x9aE6B6a74e1059AE85fAaBb4d2e00Dd719362816
            ,0x815C85346F6656eFaf56720e097e7F3527906ce0
            ,0xB47bcCc4B7343b385cE09064649246b09c2549Ff
            ,0x24B0EE9127C41F43f39a82D151A0105695cabf78
            ,0x916b42Daad94D97A0b9a41d0c26eBf7F5939b8C6
            ,0x92BE5cf1Fb733a9ad86E3393b13A6fa563356d35
            ,0xf7927d01b008D351AEEFFD6Fc0763E0f9E9c6A2c
            ,0xCeD80FD7D8C5060ac145A5b70278425d21cA3Da9
            ,0xb12DCC6D8bBea9C7A5865E8c82ff65644540915c
            ,0x4306F00Bf5A4870A40aE43917e0ff31d10F91660
            ,0xd932A7735AB6de3f1C11FC62cC449393F6418985
            ,0x47a01fCB08c8e7E29EDFe53e5824B79eaF5cF6E2
            ,0xb9236F66Aff57e14dA1F212F5A483A2Da7bA31E8
            ,0x884DA619AF1A9b6a19146ed32B481365272c2A2C
            ,0xD67D1Ff70eD1aAcEc366a994DA0Cc455aF05e251
            ,0xfAaF3d81D9a037124ab308F25d892f645D4a913e
            ,0x173712c01810448e60Ffab9680A05D64eDAB6370
            ,0xbE8f43B36B60eAa135cE7aA12cBD057700a9FBd6
            ,0x774c2B04a1b6837d8522CFe09DCb95b078e0C0B0
            ,0x16e5F71E20FBA66085B2e832a35c1d7b5CC76896
            ,0x16e5F71E20FBA66085B2e832a35c1d7b5CC76896
            ,0x16e5F71E20FBA66085B2e832a35c1d7b5CC76896
            ,0xe95D2F1C7E6643255CA180bdd6588e560FB36Ef3
            ,0xc410acd01B99B143cE182586827d8Ea55904A0DC
            ,0x834786bbF1c1F417293A03BDb7110887Ee23a2fd
            ,0xAD197744EB9D887949079027ce4da04f556679c0
            ,0x9d84BcBc31d55A187d6d6e5Ac12D79D70f123FEF
            ,0x091ab36305a5A5a45e3973aE1cAF6a2262D50e20
            ,0x9029cb2FA3e91502e213e89A14178d48fef85091
            ,0x34A13039832d75Da54b46768E5a1F492C66de511
            ,0x4c70104795Ac4E9DB353e84Eed05808F3379AeA0
            ,0x6008D8A4F8f381d77c6bf3d78896c32a9b5416c0
            ,0x966B1F330B7d574a24CC552BfD194895d283F527
            ,0xEe0540C1fa726E3D93448d306660178c939e6877
            ,0xB0CED040dbE6E8CF3A3aa3E0b7E989b63cD56539
            ,0x8F77bb8abD6bF62C0ABC35e14eaa39E80A4324Fa
            ,0x18967b29962FE61502D592f5D2A243D474F88c27
            ,0x1883e43acC37A001df3daed5f064C58195735E8d
            ,0x8De58A62ae74ed1dE328B2c5e5F6b68C16adf399
            ,0xD6B68C63efe225b9B4C86D3EB9fE9f793D893Adf
            ,0xb18e8a85043E0adaAEBd1E91541f56e3265925c3
            ,0x517DE1f16b494E04e755ccF120742150972BDD94
            ,0xC25E87c0824a3549a2b798C16053c3D808E54E42
            ,0xE3FE9A86F16322b251a1E71DE51AE3aC425E2D54
            ,0xe11C941c83dedFa902434430e21DdDfd4C93C246
            ,0x6581Aa92Fb325280252fB7bFB5C58394FfB234Fe
            ,0x7e24598128d994EE48576902C575CbE0B367B9f3
            ,0x2cA45Afeec9C4e9A0996d7BEA9E2c2115dc31614
            ,0xae5f731Da22424F63B80DCe4af7De090eBf9675D
            ,0x0649519A8B0090F9848639bF9C0dC22E60920762
            ,0x5Dad42A3870f750CC525fFDe46f3E9EF5358584B
            ,0xe0a417449F9569CFc4Be0AbB646c361EeA1c4650
            ,0xbd371D8035690C013E5d186781b13dfDc85Df9b4
            ,0xa2447719a6a278d164B53530E23E3Cc520590853
            ,0xBB7b0360354a8eEC6c9EBd06bf951a5443870111
            ,0x70F61d80F596b33B537458f82245EE48e4a53269
            ,0x55E03B6deb2dD9981FF77de73119cf2444B2CD90
            ,0xE80ea89577d241Cd9A990a0219229bc9692fA6e4
            ,0xc85CEf43dd8d4b6DB5d35E4C91FbbB989E66721D
            ,0xB7BE781c1c16dFF43FfFDE6728826CDcB724b9E3
            ,0x79907F422604355E6774b2B49c688bA633E9Bc4a
            ,0xc3a16a61aB41CE52103a73CB1C5Ab9D2f7473320
            ,0x771C3dB440ab5b9b27694398bEfCbFbe9110c3cc
            ,0x97Ea07C25a0e3c3CfDA613f548C0893a3bE48367
            ,0x2A0E0810250f306244cb3109c386a23f1Fb3971d
            ,0xeAA737789204F61691C525382f10Ae0122959417
            ,0x74D1E0C1C6c8e39d0c8431C5Da94Acdc02Bf6c10
            ,0x576806185c97aefE59f4643051F48fC8C5552c33
            ,0x767f09805B0457cdecf115D523313215a7FF6227
            ,0x67da3763245A85966d3127B7D7c010dC54F78f17
            ,0xb8108420520a2756B969035770e9D2A7E183a197
            ,0x2adEe377b30337E25a62500A3fdd23Ec3AE18799
            ,0xaf7e206E93fF4055E219ed6082a06058957b2828
            ,0xd5125862060696c431125BC3E8433DA28B6E839b
            ,0x67b37eFAF0f5AE0f1ef1D27d7b76a771C3178BE3
            ,0x6E3f16F5Dcbb855Bec47D532f4EEdDF7afc429B1
            ,0x417C03fBae7B54606098851a8c8C5Ea6686ed7e5
            ,0x9A43E2d3f7D28f0BB8A6B5952dC563AB51B8cb55
            ,0x3D9f30b402226f2082458D69CFE29c8041655D1b
            ,0x86Def65712A802192bAb0F74059Db5A3C8bA5F19
            ,0x186e8C73DDB6936dD94f87eD1CCd8dB3838F8Be0
            ,0x4EB6e57c14bd1BcBd5F882E98a2D76528F2F06A3
            ,0x1304E49aE3a764D2931bd2C406B2f99fb820AA2C
            ,0x00783Eb176f3ae0148dD0B6D65a006f625Ec3861
            ,0x1a0632d70992Bbf27F7b4FceB7A16638B4c2C7b0
            ,0x929094da87F14998BB9548502bFD822460108c59
            ,0x49Cc2Ad62ac28B9bdDbdb49545E8Ab3f7d092e9C
            ,0xFbA5798c068c3Adc805B7948c960879a611841f3
            ,0x0914B523534a1B80990414651B972C2dE47e57A3
            ,0x1Bf097971CFFfC7d19f8c4A5D9EfeeCf059384b9
            ,0x4BA9F42089FdCeeEA904E0e1a55dB104d20350D2
            ,0xE1B852BbEC7aB161D554765667814cb3Ca0ad142
            ,0x14aED17e3C22cafCd0a2d0c3d1964bE01DB0698e
            ,0x49b19bD7b939Fdc3b0b44A0F4Cb9a0aA68A27206
            ,0x88CDCea8F1eEe589944Fd6c0fd776AAfc673670d
            ,0xdBE2F9581D8C60A8180443a048E13d2DF3bebD10
            ,0x3ff6e09D274C5565084F32aFCd5410FdCd4509DB
            ,0x20de19feA264DA9CA85F661712047C0c543d4B7c
            ,0xb8D967d7fba249E47631761BaF613fb77d1DCab6
            ,0x0FefE2AA5F02d325FA4fA9AB0987A5d47bed4ad8
            ,0x4A91555066Fe178b29DF226625e87aeBF42b1371
            ,0x9cd81949D94278065F8771d8E3Def72C77fb7138
            ,0x4D272B180DCbfa0aC780d878e7da9896D889d43e
            ,0x04B5294925279a0D0218a3D401dE01b6cb1d7f19
            ,0x79A04ef83d555777d14e515e47E86A117578CD29
            ,0x59390477e58ABB0D81a4F592C62824E1E537efb7
            ,0xf3e2Faa7694317bfb254bAF5D0af850FE16026cb
            ,0xAD8C1b3b34e9e081e83665c33CB2eB17B8349626
            ,0xC7a8eB42F34c233a5663A5358b17C76cF4c345b5
            ,0x508f55b805E471904d68ccea0BB5d8268F8C14E8
            ,0x300d3DD1ace744Dc8776cFDe4Ce3EF616a5cb682
            ,0x77acAa44d5aB029f278F764c86A74944cE3836d1
            ,0x0dd7FE601593947f54d084F1Fd2892064044E6D8
            ,0xcE417772032c782d5a0e8DD0620652E8e4849fEE
            ,0x7eed21cB054fb5FD8b6908892DA078c68282F228
            ,0x6bE815B00D1DDe937c6e8717e3f5903c7C7D3aEA
            ,0x3A2A3104a9C9910cFE1c91182f26f22c2B5ffc6E
            ,0xbC070d8d8071ffb305Bc254D9c7b877468161da3
            ,0xE06f7A8606914B8644364294Ea6E042282cC82B9
            ,0x4a0f3baEa2E4F221A4F567f6E793E9865ACA1020
            ,0x11676F1325Dd1B34B33b8c409FAc1203a2238F3c];

        for (uint256 n = 0; n < list.length; n++)
        {
            addToWhitelist(list[n]);
        } 
    }

    //========================
    // CONFIG FUNCTIONS
    //========================

    function setAmountForSale(uint256 _amount) external onlyOwner
    {
        require(_amount <= 6999, "Invalid Amount");
        require(_amount > forSale, "You cant reduce amount");

        forSale = _amount;
    }

    function addToWhitelist(address _user) public onlyOwner
    {
        UserInfo storage user = userMap[_user];
        user.whitelisted = true;        
    }

    function addListToWhitelist(address[] memory _users) public onlyOwner
    {
        for (uint256 n = 0; n < _users.length; n++)
        {
            addToWhitelist(_users[n]);
        }     
    }

    function setStartTime(uint256 _startTime) external onlyOwner
    {
        require(saleStartTime == 0, "Start time already set");
        saleStartTime = _startTime;
    }

    //========================
    // SECURITY FUNCTIONS
    //========================

    function pause() external onlyOwner
    {
        _pause();
    }

    function unpause() external onlyOwner
    {
        _unpause();
    }

    //========================
    // BUYER INFO FUNCTIONS
    //========================

    function buyersLength() external view returns (uint256)
    {
        return buyers.length;
    }

    function getBuyerInfo(uint256 _index) external view returns (address, uint256, bool, uint256)
    {
        address buyer = buyers[_index];
        return getUserInfo(buyer);
    }

    function getUserInfo(address _user) public view returns (address, uint256, bool, uint256)
    {
        UserInfo storage user = userMap[_user];
        return (_user, user.bought, user.whitelisted, user.firstBuyTime);
    }

    function getUserAvailableSupply(address _user) public view returns (uint256)
    {        
        uint256 available = getAvailableSupply();
        if (block.timestamp < saleStartTime + WHITELIST_PRESALE_DURATION)
        {
            //whitelist phase
            UserInfo storage user = userMap[_user];
            uint256 whitelistAvailable = whitelistUnitsPerUser - user.bought;
            if (whitelistAvailable < available)
            {
                available = whitelistAvailable;
            }
        }

        return available;
    }

    //========================
    // BUY FUNCTIONS
    //========================

    function getAvailableSupply() public view returns (uint256)
    {
        return forSale - sold;
    }

    function getPriceForAmount(uint256 _amount) public view returns (uint256)
    {
        return _amount * pricePerUnit;
    }

    function buy(uint256 _amount) external payable whenNotPaused
    {
        //check amount & time
        require(saleStartTime != 0 && block.timestamp >= saleStartTime, "Sale hasn't started yet");
        require(_amount > 0, "Amount = 0");
        require(_amount <= getAvailableSupply(), "Invalid Amount");
        require(_amount <= getUserAvailableSupply(msg.sender), "Invalid User Amount");

        //check whitelist
        UserInfo storage user = userMap[msg.sender];
        require(user.whitelisted || block.timestamp >= saleStartTime + WHITELIST_PRESALE_DURATION, "User not on whitelist");

        //transfer        
        receiver.sendValue(getPriceForAmount(_amount));

        //send remaining back
        if (address(this).balance > 0)
        {
            payable(msg.sender).sendValue(address(this).balance);
        }

        //set data        
        if (user.bought == 0)
        {
            buyers.push(msg.sender);
            user.firstBuyTime = block.timestamp;
        }
        user.bought = user.bought + _amount;
        sold = sold + _amount;

        //event
        emit UserBuy(msg.sender, _amount);
    }
}