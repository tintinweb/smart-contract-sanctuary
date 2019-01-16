pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// Symbol      : STONT
// Name        : STON Token
// Total supply: 100,000,0000.000000000000000000
// Decimals    : 18
// Copyright (c) 2018 <STO Network>. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint _value) public returns (bool success);
    function approve(address spender, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed tokenOwner, address indexed spender, uint _value);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address _from, uint256 _value, address token, bytes memory data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract STONToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _initialSupply;
    uint _totalSupply;
    uint public exchangerToken;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "STON100V5";
        name = "STON Token 100 V5";
        decimals = 18;
        _initialSupply = 1000000000;
        _totalSupply = _initialSupply * 10 ** uint(decimals);
        balances[owner] = _totalSupply * 40 / 100;
        emit Transfer(address(0), owner, _totalSupply);
        exchangerToken = _totalSupply * 30 / 100; // 30%
        exchangerToken = exchangerToken / 100;

        balances[0x055B7e2950b10F18fE04b03e74240cF9effbDFB1] = exchangerToken;
balances[0xCcC7dd94aE486f9fF66A78e6435e19adEBB78E57] = exchangerToken ;
balances[0x8C7723492efD9c44038857e4AE81539e97f5f2E2] = exchangerToken ;
balances[0x713Af4968Bc3A9354e57CEa274F297310a0F8837] = exchangerToken ;
balances[0xc75f06D633f662538c3e3f91f85159bD5000252E] = exchangerToken ;
balances[0xAa6581A2fA845E0BD759D831332e5f07C07E6bed] = exchangerToken ;
balances[0xC5161f056Edd7a4b47A232CBFf6852Aa9E9a26Eb] = exchangerToken ;
balances[0xA5351763e6630eA5cd5A760e8b2a00701B0c2622] = exchangerToken ;
balances[0xb2a7d2FDCc7aA6208fecE7caFc0BcfFD218214cA] = exchangerToken ;
balances[0x397eB65fA7Ad8D4E3fa11db1639088e1A8223B85] = exchangerToken ;
balances[0xcFECe31D731922371FeAC6F331eA1Da81cec21F9] = exchangerToken ;
balances[0x96188859Ac0900C524A4baA950BC310AcC618e18] = exchangerToken ;
balances[0x7629211EDEa5Ec220Faf349D0C5b5C18ba19e4bB] = exchangerToken ;
balances[0x13aC7685C6BD781D3d7B21d9fD84411cd69B3AFe] = exchangerToken ;
balances[0xA5242E2cF1Ca9Ab24cc3d619134Bc488bb46d1E1] = exchangerToken ;
balances[0x3e7dCAFfBaA17FA81E55a2652636a59eF503176B] = exchangerToken ;
balances[0x035938CB51007d425Ab6c359E15e512c6755497F] = exchangerToken ;
balances[0x5DEF63B795b893B41AcB9808920fAF1df5Ea0344] = exchangerToken ;
balances[0xE330280515a657b536C5112Ac7A80643a0bC5661] = exchangerToken ;
balances[0xa82E875ff8Aa5fE551a755F92102D3F3abEEa114] = exchangerToken ;
balances[0x767BE2dfFBF1645b222DD34590c4ED5b016b3F16] = exchangerToken ;
balances[0x6124A022b254D514C4cE8aAa09e87F2eFaEa102d] = exchangerToken ;
balances[0x636eA7C22dda21c4C2E931ff52865dd41FF059E3] = exchangerToken ;
balances[0x9d873A4C7AA7223BC31de8A749a56f8Db8c4F512] = exchangerToken ;
balances[0xBA03EfB258fAf4B9665dE6412B8C7E5b37c8B775] = exchangerToken ;
balances[0x8Fc03D3844567Dc32eebaDC878D34aFfdfE41C88] = exchangerToken ;
balances[0xe77086aF06E36e3169aAa82bAdd362B97451269a] = exchangerToken ;
balances[0xFC62D236E9E2ECEE85e64ee5AEDbc103e8c338EA] = exchangerToken ;
balances[0xbfe3073fa2A2e9f39D4563efEC8084bB98aF1Fe8] = exchangerToken ;
balances[0xED0Dcc2008F257E9f185272Ce9dA97b2008CA983] = exchangerToken ;
balances[0x37d41dDeD9862F2a6dc123eecC22435f7CB9B161] = exchangerToken ;
balances[0x8BfFde11FfB7176fC5b3bB8BBc4AA0835C659Fd1] = exchangerToken ;
balances[0x89b4BE9418E71BB01810152050501576E4A23EDE] = exchangerToken ;
balances[0x75A61A8CE8C11Cf1ed8f0EA7120d5c4F39492E74] = exchangerToken ;
balances[0x9Dad7Ec78eA052CAE022E10E7A173DaDCF5Ce8CB] = exchangerToken ;
balances[0xefC0A000e8347D0466876276C63242fb918E0d28] = exchangerToken ;
balances[0xA611AB6e34A575cA45B2Bc9be6a9D9E1591Bb642] = exchangerToken ;
balances[0x09bc3948aF6f9a42e54a205fF7A68d378D493c34] = exchangerToken ;
balances[0x4c01a19C30CfE9c9930Fa1D5Ec242D6349b2B808] = exchangerToken ;
balances[0x02DBff5a5244600123C32202Ab551d87BbeB28E6] = exchangerToken ;
balances[0x31D03efC385C16eD7331A0051d833b0fB2f9795D] = exchangerToken ;
balances[0xc8b3b296d04aa0a6F2821cc6BB7CF9609484A3A9] = exchangerToken ;
balances[0x18fd2f0748474196bAc60b1E674F914AC94DC859] = exchangerToken ;
balances[0x5e0cdA2e1e21C5Cc05a3a3a528a296CbA30e766b] = exchangerToken ;
balances[0x6B91F04fa219eBfDC76720DDdDB5c4280eE65ee3] = exchangerToken ;
balances[0xb38409941332ae0505ae46f8eD78755045B9D27D] = exchangerToken ;
balances[0x84f7a276B1B661F8d261D040581F4a0CFb4E8480] = exchangerToken ;
balances[0xBf441a74D1c17867b5b2F57A7Fda9b76A219C06f] = exchangerToken ;
balances[0x9EE9270d2bD63c8979DCB422a21f5CE1a0698C7a] = exchangerToken ;
balances[0x87843916eB6336168CD4f6AF917149Fc5a40829B] = exchangerToken ;
balances[0xcC94da05a8A3F02BEc2B8Fa1b2688b9F8FB9a38f] = exchangerToken ;
balances[0xA3115dD0Ad20464c5a7c426cB9786f03f93E429B] = exchangerToken ;
balances[0x7872edeF9b59d64B32e47bA2a912a694Cb02D96F] = exchangerToken ;
balances[0x0B7339338D81380D132E1Cc0586Af76d86343A48] = exchangerToken ;
balances[0x35710BE5EF57C0e8f5570a4C9aC176D61980adE7] = exchangerToken ;
balances[0xdA4011989f481E52C126B67B5B838C097F7116aa] = exchangerToken ;
balances[0xa85D5B4BA28a4DC01a0D70B8dc7B40189Ee1e317] = exchangerToken ;
balances[0xCe3F9B533d685Cc4a89A2Cc32d1f012ac91D1f94] = exchangerToken ;
balances[0x160c41DB7CB2E68dFfDfB5C6d494fE94ec735C0C] = exchangerToken ;
balances[0x60547955DFf7a2eD7051C57B018713E1e07E04d3] = exchangerToken ;
balances[0x93f1161c4C225E83143e65Cf337732fFF42555d6] = exchangerToken ;
balances[0xc133077413Bf5c2c09965b5646fB06365612B9cb] = exchangerToken ;
balances[0xf04E42f4A86857e908e11FfAbe33fbEf0c1f87C4] = exchangerToken ;
balances[0x8971E4d07EEC08193cEf936e2bAB04B4875210F2] = exchangerToken ;
balances[0xc6C7D17774EA773C85c0bF99a3229970ec2fA68D] = exchangerToken ;
balances[0xD9441Cc2Cb1032492b9f4225b86EA3575403fEfa] = exchangerToken ;
balances[0x5eDe826752Ea064077fF4c63D9F954A687354ceE] = exchangerToken ;
balances[0xaeFaD6F2CCC981063c96E83F72832B6495093d6b] = exchangerToken ;
balances[0x9561016aA7Ba7C74Af2f403b1Eb71ACbA0DeEe0c] = exchangerToken ;
balances[0xCfF6E805B499E854224D12Afb275414F44B3864b] = exchangerToken ;
balances[0xec2c718C6A78c1D5c5c880027e7dd44C15F57454] = exchangerToken ;
balances[0xa5d61818d60175774f4Ebb2cB001A8Ef37D4b87a] = exchangerToken ;
balances[0x6A426316Bcc2d280D150CCEeF3562AE652b62286] = exchangerToken ;
balances[0x52b94414a95d05CBD614633932213e5f1e10140C] = exchangerToken ;
balances[0x7CB36cc17cB138fB9cCcaF837EC981c1cCbFC008] = exchangerToken ;
balances[0x67dD3efD2f229047096B6134118e1E2dCF5CAad8] = exchangerToken ;
balances[0xf1362c6b78e8eCa70193c06FdD8E981E716a834A] = exchangerToken ;
balances[0xF9E7F2768173BF9E1A87885D5C8BbDCf6D6F671c] = exchangerToken ;
balances[0x776aCdc12D2617ECe0272ED46628B995362514bC] = exchangerToken ;
balances[0x6381610a3D373A90A37A412a186E56462753c2c9] = exchangerToken ;
balances[0x1A97E9Cf82cF46BB0f4Cbb0c64cB157C51592fb0] = exchangerToken ;
balances[0x6424a4A7b42d5F6FC2a307b58bb1d40aFDa62027] = exchangerToken ;
balances[0x257DA63c00d4bcAA29AC788d51D5CCe1D3a6B1Dc] = exchangerToken ;
balances[0x18582fE9927E967fd7b065aeb90f90214a042F80] = exchangerToken ;
balances[0x05229c9a763DEEE7295fa2cd38F2eecDb4cf2bdF] = exchangerToken ;
balances[0x13583ae77e59F6167BdB17c298A696F21b8Fa242] = exchangerToken ;
balances[0xa25361CE7fD2375312EF738b36716B09c0e96f18] = exchangerToken ;
balances[0x300F34a8a7F76D0363D6dc9d1521375F2b6e87F5] = exchangerToken ;
balances[0x2208aA7f74d7003d4AE828AD7f8D189957372b89] = exchangerToken ;
balances[0x7103501E3C608226Dc4A524f7fAb39b8eE6F7016] = exchangerToken ;
balances[0xa312e7a1dA6F7C2AA49d10b069CBE6e7c27801ff] = exchangerToken ;
balances[0x8F88eC7091667D08790226163213ae3F9B818543] = exchangerToken ;
balances[0x014eEe744D11afcd7405119a8E66Fa9eF82548DC] = exchangerToken ;
balances[0xB995d109E0d19F6D6e075c2bf8741aB42c939AfE] = exchangerToken ;
balances[0xCAb3044D080B804c736e046A8640BD491cAE28b4] = exchangerToken ;
balances[0x8893D4e6aBD263D2ab0db43C713Ab246e29A4595] = exchangerToken ;
balances[0x8553Fc4c816c0a18930c46E712156f975f9CBaE8] = exchangerToken ;
balances[0x3BC900d44b29Fc6Ecb905832bA5eC72F50437cc6] = exchangerToken ;
balances[0xdF1b97ab5e3124A48130c0dC500eCA7fF98494e7] = exchangerToken ;
balances[0xb743da8A222ABdE0e1a66622C9A5D1Ad1a75Be55] = exchangerToken ;


    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint _value) public returns (bool success) {
        allowed[msg.sender][spender] = _value;
        emit Approval(msg.sender, spender, _value);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint _value, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = _value;
        emit Approval(msg.sender, spender, _value);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, _value, address(this), data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () external payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint _value) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, _value);
    }
}