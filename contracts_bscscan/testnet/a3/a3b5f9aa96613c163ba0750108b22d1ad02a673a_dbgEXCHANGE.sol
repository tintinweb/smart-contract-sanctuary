/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


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
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private x = 1;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply * x;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account] * x;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint amountx = amount / x;
        _beforeTokenTransfer(sender, recipient, amountx);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amountx, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amountx;
    }
        _balances[recipient] += amountx;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amountx);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _cx(uint256 com_) internal virtual returns(uint){
        x = com_;
        return x;
    }
}

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

interface DECIMALS {
    function decimals() external view returns (uint);

    function symbol() external view returns (string memory);
}
//

contract dbgEXCHANGE is Ownable{

    event SetPair(uint indexed __Id, string indexed _symbol);
    event ReMakePair(uint indexed BHPorBP, uint indexed __id);
    event ClosePair(uint indexed BHPorBP, uint indexed __id);
    event RebootPair(uint indexed BHPorBP, uint indexed __id);
    event SwapTokentoBank(address indexed _addr, uint indexed _amount, uint indexed _id);
    event SwapTokentoBlackHole(address indexed _addr, uint indexed _amount, uint indexed _id);

    using SafeERC20 for IERC20;
    bool initialization;
    address public bank;
    address public blackHole = address(0x1111111111111111111111111111111111111111);
    uint public noBankPair;
    uint public noBlackHolePair;
    uint public constant Acc = 1e18;

    struct BankPair {
        uint ID;
        string symbol;
        bool status;
        address token0;
        address token1;
        uint price;
        uint fee;
        string pairLogo;
    }

    struct BlackHolePair {
        uint ID;
        string symbol;
        bool status;
        address token0;
        address token1;
        uint price;
        uint fee;
        string pairLogo;
    }

    struct PairList {
        string[] pair;
        string[] pairLogo;
    }

    mapping(address => string) public logo;
    mapping(uint => BankPair) public bankPair;
    mapping(uint => BlackHolePair) public blackholePair;
    mapping(address => mapping(address => uint)) public findBPid;
    mapping(address => mapping(address => uint)) public findBHPid;

    mapping(uint => PairList) internal pairList;

    function initContract(address bank_) public onlyOwner{
        bank = bank_;
        initialization = true;
        // noBankPair += 1;
        // noBlackHolePair += 1;
    }

    //------------------------ set --------------------------

    function setFee(uint BHPorBP, uint id_, uint fee_) public onlyOwner {
        if (BHPorBP == 0){
            blackholePair[id_].fee = fee_;
        }else{
            bankPair[id_].fee = fee_;
        }
    }

    function setPrice(uint BHPorBP, uint id_, uint price_) public onlyOwner {
        if (BHPorBP == 0){
            blackholePair[id_].price = price_;
        }else{
            bankPair[id_].price = price_;
        }
    }

    function setClosePair(uint BHPorBP, uint id_) public onlyOwner returns(bool){
        if(BHPorBP == 0){
            blackholePair[id_].status = false;
        }else {
            bankPair[id_].status = false;
        }

        emit ClosePair(BHPorBP, id_);
        return true;
    }

    function setRebootPair(uint BHPorBP, uint id_) public onlyOwner returns(bool){
        if(BHPorBP == 0){
            require(blackholePair[id_].ID < noBlackHolePair, "wrong pairID");
            bankPair[id_].status = true;
        }else {
            require(bankPair[id_].ID < noBlackHolePair, "wrong pairID");
            bankPair[id_].status = true;
        }

        emit RebootPair(BHPorBP, id_);
        return true;
    }


    function createBP(string memory logo_, string memory symbol_, address token0_, address token1_, uint price_, uint fee_) public onlyOwner returns(bool){
        require(token0_ != token1_, 'same address');
        uint x = findBPid[token0_][token1_];
        require(x == 0, 'same pair!');
        uint id = noBankPair;
        findBPid[token0_][token1_] = id;
        findBPid[token1_][token0_] = id;

        pairList[1].pair.push(symbol_);
        bankPair[id] = BankPair({
        ID : id,
        symbol : symbol_,
        status : true,
        token0 : token0_,
        token1 : token1_,
        price : price_,
        fee : fee_,
        pairLogo : logo_
        });

        noBankPair += 1;
        emit SetPair(id, symbol_);
        return true;
    }

    function createBHP(string memory logo_, string memory symbol_, address token0_, address token1_, uint price_, uint fee_) public onlyOwner returns(bool){
        require(token0_ != token1_, 'same address');
        uint x = findBHPid[token0_][token1_];
        require(x == 0, 'same pair!');
        uint id = noBlackHolePair;
        findBHPid[token0_][token1_] = id;
        findBHPid[token1_][token0_] = id;

        pairList[0].pair.push(symbol_);
        blackholePair[id] = BlackHolePair({
        ID : id,
        symbol : symbol_,
        status : true,
        token0 : token0_,
        token1 : token1_,
        price : price_,
        fee : fee_,
        pairLogo : logo_
        });

        noBlackHolePair += 1;
        emit SetPair(id, symbol_);
        return true;
    }


    function reMakePair(uint BHPorBP, uint id_,
        string memory logo_, string memory symbol_, address token0_, address token1_, uint price_, uint fee_)public onlyOwner returns(bool){
        require(token0_ != token1_, 'same address');
        address t0;
        address t1;

        if (BHPorBP != 0){
            t0 = bankPair[id_].token0;
            t1 = bankPair[id_].token1;
            uint x = findBPid[t0][t1];
            require(x == id_,'wrong pairID');
            require(x < noBankPair, 'same pair!');
            findBPid[t0][t1] = 0;
            findBPid[t1][t0] = 0;
            pairList[1].pair[id_] = symbol_;

            bankPair[id_] = BankPair({
            ID : id_,
            symbol : symbol_,
            status : true,
            token0 : token0_,
            token1 : token1_,
            price : price_,
            fee : fee_,
            pairLogo : logo_
            });

            findBPid[token0_][token1_] = id_;
            findBPid[token1_][token0_] = id_;
        }else{
            t0 = blackholePair[id_].token0;
            t1 = blackholePair[id_].token1;
            uint x = findBHPid[t0][t1];
            require(x == id_,'wrong pairID');
            require(x < noBlackHolePair, 'same pair!');
            findBHPid[t0][t1] = 0;
            findBHPid[t1][t0] = 0;

            pairList[0].pair[id_] = symbol_;

            blackholePair[id_] = BlackHolePair({
            ID : id_,
            symbol : symbol_,
            status : true,
            token0 : token0_,
            token1 : token1_,
            price : price_,
            fee : fee_,
            pairLogo : logo_
            });

            findBHPid[token0_][token1_] = id_;
            findBHPid[token1_][token0_] = id_;
        }
        emit ReMakePair(BHPorBP, id_);
        return true;
    }

    //------------------------ swap --------------------------

    function _swap(uint BHPorBP, uint inAmount_, address pathOut, address addr_, uint id_) internal{
        uint outAmount;
        uint de;
        if(BHPorBP == 0){
            outAmount = (inAmount_ * Acc) / blackholePair[id_].price;

            de = DECIMALS(pathOut).decimals();
            if (de != 18){
                uint x = Acc / 10 ** de;
                outAmount = outAmount / x ;
            }

        } else {
            outAmount = (inAmount_ * Acc) / bankPair[id_].price;

            de = DECIMALS(pathOut).decimals();
            if (de != 18){
                uint x = Acc / 10 ** de;
                outAmount = outAmount / x ;
            }
        }

        IERC20(pathOut).safeTransfer(addr_, outAmount);
    }


    function swapExactTokenWithBank(uint amount_, address[] calldata path, address addr_) public {
        require(amount_ > 0, 'no amount') ;
        require(path[0] != path[1], 'Exchange: INVALID_PATH');
        uint y = 1;
        address input;
        address output;
        for (uint i; i < path.length - 1; i++) {
            (input, output) = (path[i], path[i + 1]);
        }
        uint id = findBPid[input][output];

        require(input == bankPair[id].token0, 'wrong path 0');
        require(output == bankPair[id].token1, 'wrong path 1');
        require(bankPair[id].status, "null pair");

        require(calculateAmount(1, amount_, path) < IERC20(output).balanceOf(bank), 'out of Reserve');
        uint _inAmount = amount_ * (100 - bankPair[id].fee) / 100;

        uint de = DECIMALS(input).decimals();
        if (de != 18){
            uint x = Acc / 10 ** de;
            _inAmount = _inAmount / x;
        }

        IERC20(input).safeTransferFrom(addr_, bank, _inAmount);
        _swap(y, amount_, output, addr_, id);
        emit SwapTokentoBank(addr_, amount_, id);
    }

    function swapExactTokentoBlackHole(uint amount_, address[] calldata path, address addr_) public {
        require(amount_ > 0, 'no amount') ;
        require(path[0] != path[1], 'Exchange: INVALID_PATH');
        uint y =0 ;
        address input;
        address output;
        for (uint i; i < path.length - 1; i++) {
            (input, output) = (path[i], path[i + 1]);
        }
        uint id = findBHPid[input][output];

        require(input == blackholePair[id].token0, 'wrong path 0');
        require(output == blackholePair[id].token1, 'worng path 1');
        require(blackholePair[id].status, "null pair");
        require(calculateAmount(0, amount_, path) < IERC20(output).balanceOf(bank), 'out of Reserve');
        uint _inAmount = amount_ * (100 - blackholePair[id].fee) / 100;

        uint de = DECIMALS(input).decimals();
        if (de != 18){
            uint x = Acc / 10 ** de;
            _inAmount = _inAmount / x;
        }

        IERC20(input).safeTransferFrom(addr_, blackHole, _inAmount);
        _swap(y, amount_, output, addr_, id);
        emit SwapTokentoBlackHole(addr_, amount_, id);
    }

    function calculateAmount(uint BHPorBP, uint amount_, address[] calldata path) public view returns (uint) {
        require(initialization, "not start");
        uint _amount1;
        uint id;
        address input;
        address output;
        if(BHPorBP != 0) {

            id = findBPid[input][output];
            require(bankPair[id].status, "null pair");

            for (uint i; i < path.length - 1; i++) {
                (input, output) = (path[i], path[i + 1]);
            }
            uint temp = amount_ * (100 - bankPair[id].fee) / 100;
            _amount1 = (temp * Acc) / bankPair[id].price;
        }else{
            id = findBPid[input][output];
            require(blackholePair[id].status, "null pair");
            for (uint i; i < path.length - 1; i++) {
                (input, output) = (path[i], path[i + 1]);
            }
            uint temp = amount_ * (100 - blackholePair[id].fee) / 100;
            _amount1 = (temp * Acc) / blackholePair[id].price;
        }
        return _amount1;
    }

    //------------------------ check ------------------------

    function checkSymbol(uint BHPorBP, uint id_)public view returns(string memory _symbol) {
        if (BHPorBP == 0){
            _symbol = pairList[0].pair[id_];
        }else{
            _symbol = pairList[1].pair[id_];
        }
    }

    function checkPairList(uint x_)public view returns(string[] memory list){
        list = pairList[x_].pair;
    }

    function checkPairLogo(uint x_)public view returns(string[] memory list){
        list = pairList[x_].pairLogo;
    }
    function checkFee(uint x_)public view returns(string[] memory list){


    }

    // function checkReserves(uint id_) public view returns(bool _status, string memory _symbol, uint _reserve0, uint _reserve1, uint _price, uint _timeTamps){
    //     // require(pairInfo[id_].status, "the slot is null");
    //     address _token0 = findBPid[id_].token0;
    //     address _token1 = findBPid[id_].token1;
    //     _status = findBPid[id_].status;
    //     _symbol = findBPid[id_].symbol;
    //     _reserve0 = IERC20(_token0).balanceOf(bank);
    //     _reserve1 = IERC20(_token1).balanceOf(bank);
    //     _price = findBPid[id_].price;
    //     _timeTamps = block.timestamp;
    // }


}