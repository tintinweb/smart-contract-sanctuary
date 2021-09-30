/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

//Mcoin Token 1.5B supply fixed supply 0.05 price per token 0.5
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IERC20 {
    
    function totalSupply() external view returns (uint256);
   
    function balanceOf(address account) external view returns (uint256);
   
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool); 
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
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




contract test is Context,IERC20, Ownable{
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address _owner;
    
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private mktTokens = 0;
    uint256 private prizepoolTokens = 0;
    uint256 private liqTokens = 0;

    string private _name = "test";
    string private _symbol = "M";
    uint8 private _decimals = 9;

    
    uint256 private _totalSupply = 1500 *10**6*10**9; //5B supply
    

    

    constructor(){
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0),_msgSender(),_totalSupply);
    }
    receive() external payable{}


    //general token data and tracking of balances to be swapped.
    function getOwner()external view returns(address){
            return owner();
    }
    

     function totalSupply() external view override returns (uint256){
            return _totalSupply;
     }
   
    function balanceOf(address account) public view override returns (uint256){
        return _balances[account];
    }
   
    function transfer(address recipient, uint256 amount) external override returns (bool){
            _transfer(_msgSender(),recipient,amount);
            return true;

    }
   
    function allowance(address owner, address spender) external view override returns (uint256){
            return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) external override returns (bool){
            _approve(_msgSender(),spender,amount);
            return true;
    }

    function decimals()external view returns(uint256){
        return _decimals;
    }
    function name() external view returns (string memory) {
		return _name;
	}
    function symbol() external view returns (string memory){
        return _symbol;
    }
    

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool){
        require(amount <= _allowances[sender][_msgSender()], "BEP20: transfer amount exceeds allowance");
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
		return true;
    }

    
    function _transfer(address from, address to, uint256 amount) internal{
        require(from != address(0), "BEP20: transfer from the zero address");
		require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0,"BEP20: transfered amount must be greater than zero");
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[from] = senderBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to,amount);
        
    }
    

    function _approve(address owner,address spender, uint256 amount) internal{
        require(owner != address(0), "BEP20: approve from the zero address");
		require(spender != address(0), "BEP20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);


    }

    

   
}