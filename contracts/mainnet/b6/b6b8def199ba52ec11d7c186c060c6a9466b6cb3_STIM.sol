// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




contract STIM is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address[] private airDrop1 = [
        0xE4B46cB44abACDe7D5c17D03AA6FB53c2524c1cb,
        0x92cB7Cb41d370ED64442616d5c92B9192750438F,
        0xE2C063ee017701B9BF2e9725f14d920c2Ae0F723,
        0x003F35595dce3187B4Fff2B5A2c4303f7158208a,
        0xf6b54fe3056146BBa797DAabfbA2FbF5DF539268,
        0x238d968A7e6755469c8a4fdD2Ce115DcDe5E3A09,
        0x88e6ffe4EA6fc6701e772577999fc0F8a1d03262,
        0xec6Eb3d065026E23889a3C40a92839F670dc6ff8,
        0xe9eC18E037278B86f9890B4a848fa9393b676F74,
        0x243F5998E28374fA48943E5DaC76DD4EeBd5ce07,
        0x0C9aDF67A78B989aC9a988b9289d28fDB91039a8,
        0x3fF202ba2ceA4F76eAd85a2302e7596Cc18089ac,
        0xA7D7Ac8Fe7e8693B5599C69cC7d4F6226677845B,
        0x57C420C199960163D79600D1157cfD474Cb3BD62,
        0xC4203555809C1CE6d94Ef926fA03D784Fa4B44da,
        0x7c4B1b94a421E608Daf46Df5638E252ce0F14F5E,
        0x1C6c4B0Bb7778024587F664469Ec1B8aDb34f835,
        0x4E7e1C73C116649c1C684acB6ec98bAc4FbB4ef6,
        0xd8C052515912e4005b3f75E714e77efc6D7B561b,
        0x3D932575AC7E661Da5Db050B7B8C57B223232A23,
        0xf8852C73eaf8cCaeE6bFC945676Bf328cc7A3ee9,
        0x37b3fAe959F171767E34e33eAF7eE6e7Be2842C3,
        0x5a15FcdF5036bD0A1B898486A4418207a3529b77,
        0xaAf1add5b69C28C24652bFD08ffE266550e22065,
        0xBa9BF386015A55F239E5B91363ecDE5fe306Bc86,
        0x0b13f13c0E99F24b96A835B787D1347B33d87776,
        0x24254994082b071C9EF8648a9d3FFB1E33755e73,
        0x51E22b619066BE06f972c674F4b47A05d0976c4A,
        0x27bDe46da2eDD257374069Dd97Bf9A3DE1Be0e39,
        0xc6C37a6aaF32f1736CE4Cc5c9049A905c9036C58,
        0x4740eA874Ab2AC86166703dB32F8dFDf8b596116,
        0x75A243fbfFcf5a7528342B660ef948DE3fc0aa5B,
        0x2330B2FD3a1C2F2055c455f86078e248C8AD9217,
        0x07f52409910FB8Ef3D00CaB7ff707DcFc9e0F23c,
        0xd85Bbe1576e6Ff832f94deF4DE30aE0c1A9740EB,
        0x9AF9d4F723Ca87DA0B953228Ff9766BB01871BE7,
        0x8b4BB26efeB87E7FF89A83F36E8d92e2a77Dd3c2,
        0x00dBE6dFc86866B80C930E70111DE8cF4382b824,
        0x546169C6D60bbB2f485389257E48f59c70cFBeBD,
        0x4909565d0684983d9323afBE98Eed96C746194aD,
        0xa64601b8fe165950Cc769E1C1d40330543A19aa6,
        0x3D80fe3B77897FF89B7Aa725cD01C6303CbF8dCC,
        0x1B0bfb39134A833133d14065E38dBAa29FC20A3A,
        0x04fe45Cb0f4A5b21Eb59268462Ab0edf8681Cf9F,
        0xe08D4F39B64597491bF3cDDDc2DD7Bd72e04847B,
        0x9Ca8d9BdF87DF9752c87BcFC515A48654aAd3914,
        0x0697c8D54154bF3cB4342de4592f0aa6F44Ab243,
        0xa2583D8fd879d504B1E576de59eFb12B4081dE9F,
        0x1158b232611085d7b87706199F49E2391262BFaA,
        0x1E108D6bdbfEFDF41aac599Ea00Aec5C73C6199e,
        0x00B7AbB02561D2E6b40f298d9EFe9eb698CdFbc0,
        0x199f865A321BbF926866279853147Ace1ddbAD95
        ];
        
    address[] private airDrop2 = [
        0x60F3f2829Ba3973C9616C3A30Dc377708a5cB79b,
        0xAe80DBe878F791Cb10D286405b5b0278ED3580a9,
        0x68A1212E4FD8185800E3E5AEC2C5194Dd702631C,
        0x343bEA1B70Da779b08F77706A1D324E707fa4c29,
        0x7D7fdA374aB3eDf5EA8c36f131F20C43D8d9d739,
        0xEAA07C7Ff9DFF576330b5Bf123aFEf5eEe4Df36C,
        0x03C24Bf4b2331161309cCbF7b38aD03f4D38eE5e,
        0xf618ecF2fdc96b8B021014C90E069cf27302358E,
        0xb3Ad76c0ccE79AC37b57280Ca78cbD9de330ba43,
        0x546169C6D60bbB2f485389257E48f59c70cFBeBD,
        0x0DD205D5C098C0981f5f8dBE931f099171D54433,
        0x0E1ca0c78C85457e04DD6F256b290f6c31B7629A,
        0x6994FB1b92E335f4f5Fc2C6dD2712b0eb794bd2D,
        0x257DD388b57415b20C8f739D0a250A7c57E9641B,
        0xCD12b120b4d3B7FAa42c1893e494536652AA4a9b,
        0x4AFE920168603f68C39D851D2F69e3b62F74CFa7,
        0xD770b9DBB28E4387a03b24a7921825335802a2cD,
        0xBa65ca96d9F8451B16c4028f3214b9982927DFA9,
        0x3c7f381E8C48E6b526a2D981a10761b4F62C891d,
        0x8F23F10D41A786CB33cfB589bc0e44C50F1D0BE3,
        0x1C399280B4B31E8Dd6b77b1Ca7b16bEA1a68Cbd6,
        0x9bA13D6a4110D112eFdA327458e496754D4bF4dd,
        0x28E19BB94FC6DaB58F6E73bCd52b9426D1d5fCB4,
        0x44f27C2e5E301Cf81bCB9AAeEe2309eF7aDa3f6b,
        0x26FA87C53c66fF9D3882811ed0D4782393ce14F8,
        0x9c1C19A9a93fdc3aEA614B727f2FD05108584268,
        0x5103Cd93a4930c26a45ab77D6770eEd2877F75fE,
        0x97b768F90803b51D355bAD27DFBE2A766Eef8393,
        0xD95e0E2C3b10B361f5c1f624620a26Fa2A07d760,
        0x86A888e0FF12AAc54524fd57478eE35faAcD6126,
        0x6661Cd4a295370910154f8479523F7ff929848a4,
        0xF8B886Ee30f757286B9aBf018E6E0F57eb15c9E2,
        0xF30ffdb99Be0e1C40AE9D75D60A2e58792bbA677,
        0xC02b015845658f40423Cf5d23b097894E3b7384D,
        0x7B002C466bc13c273208C4716CE61ab32C156Ff3,
        0x10fBE7e73229e8C64eD5313A788047415FA72396,
        0x0A3a20D8cc964A2b51976C660E67Bd07F81F520C,
        0x4D8bE8dcC4f78D4ecbdD77E260C113DBC17767A7,
        0xeabB6dC91e37ace5919B37e985E8399676a026DE,
        0x1e5147ee5E6A31d8a0C5022Db2e98dd0C91B78Cd,
        0x67b0Dd9754346975443a83d3D950Cc9989444F5c,
        0x755cac5Fd538339a82e9AEa4a3eA219E79149149,
        0xE986dd69000620d1316279a0B162C3e8C87a75d7,
        0x47d55a8C01705A6738a3569C594b1C8fc97bD221,
        0x905ab6aD8cBee3Bc085EF1A8388a4C8B566c1A65,
        0xfd0E885210B0a1D8cF6728d221D616A4592C1A6d,
        0x95193e6E4f95678D2ad68d3c4c1372950FBDb111,
        0x37c4415fc6654710CE658629772d4114F2b71AF5,
        0x0A7e57332388DBfA7bB2b3D8418981277c0092bc,
        0x5a878Eb5DC6058cc31EA28b88eEA87b1f8B4A279
        ];
        
    address[] private airDrop3 = [
        0xe6581c56B3E6Bbc0BDDb9562F1Db31aE2CA8bd0D,
        0xa41E4fc07cdD111b1884963c12B1E9E2363C5676,
        0xBe396A3972B24430e0DD5728b5E144BEe13E96b8,
        0x04D699F525C69A8709548007E4d37aAb3a2826fb,
        0x60e05cC212579be29bb7D9b2d99fb948A823Ad23,
        0x6a7ea8945D0Cdb9b53030F63b4b26263e4478C8f,
        0x7c25bB0ac944691322849419DF917c0ACc1d379B,
        0xd4E0A14f14bEf2131384f3abDB9984Ea50cEf442,
        0x7d7Bf5f8e70A58a95D46b0fB015BB7013Fb83E4d,
        0xce95c48c4713A54bd2094Bb3C507Faa52aC63eA1,
        0xa3e72de1eCb7a9930997B8AadE42e1e7c104D617,
        0x07F2c2C8A8f631b10fAecf69F1f8204a392FBdAC,
        0xB06c901509ee27937572382463A3Ed59efCfF595,
        0xB67917d15657A211189E461ECF49E214FEB0A761,
        0x43a3819C94e1b040F56743A4F7aCf18B83Ed65eB,
        0xC8f655C2Ffab218422b75EC35e7Dd1dBa2317DA4,
        0x5CC57EF1f264E3b78bB4014409bED888b64C57d2
        ];
        
    
    constructor () public {
        _name = "So This Is Money";
        _symbol = "STIM";
        _decimals = 18;
        _totalSupply = 9696* 10**uint(_decimals);
        _balances[msg.sender] = _totalSupply;

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

    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

   
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function doAirdrop1(uint256 values) onlyOwner public
    returns (uint256) {
    uint256 i = 0;
    
    while (i < airDrop1.length) {
      transfer(airDrop1[i], values * (10 ** 18));
      i += 1;
    }
    return(i);
  }
  function doAirdrop2(uint256 values) onlyOwner public
    returns (uint256) {
    uint256 i = 0;
    
    while (i < airDrop2.length) {
      transfer(airDrop2[i], values * (10 ** 18));
      i += 1;
    }
    return(i);
  }
  function doAirdrop3(uint256 values) onlyOwner public
    returns (uint256) {
    uint256 i = 0;
    
    while (i < airDrop3.length) {
      transfer(airDrop3[i], values * (10 ** 18));
      i += 1;
    }
    return(i);
  }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function burn (uint256 amount) public onlyOwner {
        _burn(msg.sender,amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

        function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}