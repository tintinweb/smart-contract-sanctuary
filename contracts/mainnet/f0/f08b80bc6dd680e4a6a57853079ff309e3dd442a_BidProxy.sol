pragma solidity ^0.6.0; abstract contract Gem {
    function dec() virtual public returns (uint);
    function gem() virtual public returns (Gem);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;

    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public returns (bool);
    function transferFrom(address, address, uint) virtual public returns (bool);
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
    function allowance(address, address) virtual public returns (uint);
} abstract contract Join {
    bytes32 public ilk;

    function dec() virtual public view returns (uint);
    function gem() virtual public view returns (Gem);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
} interface ERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
} abstract contract Vat {

    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
    }

    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
        uint256 dust;  // Urn Debt Floor            [rad]
    }

    mapping (bytes32 => mapping (address => Urn )) public urns;
    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]

    function can(address, address) virtual public view returns (uint);
    function dai(address) virtual public view returns (uint);
    function frob(bytes32, address, address, address, int, int) virtual public;
    function hope(address) virtual public;
    function move(address, address, uint) virtual public;
    function fork(bytes32, address, address, int, int) virtual public;
} abstract contract Flipper {
    function bids(uint _bidId) public virtual returns (uint256, uint256, address, uint48, uint48, address, address, uint256);
    function tend(uint id, uint lot, uint bid) virtual external;
    function dent(uint id, uint lot, uint bid) virtual external;
    function deal(uint id) virtual external;
} contract BidProxy {

    address public constant DAI_JOIN = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;

    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function daiBid(uint _bidId, uint _amount, address _flipper) public {
        uint tendAmount = _amount * (10 ** 27);

        joinDai(_amount);

        (, uint lot, , , , , , ) = Flipper(_flipper).bids(_bidId);

        Vat(VAT_ADDRESS).hope(_flipper);

        Flipper(_flipper).tend(_bidId, lot, tendAmount);
    }

    function collateralBid(uint _bidId, uint _amount, address _flipper) public {
        (uint bid, , , , , , , ) = Flipper(_flipper).bids(_bidId);

        joinDai(bid / (10**27));

        Vat(VAT_ADDRESS).hope(_flipper);

        Flipper(_flipper).dent(_bidId, _amount, bid);
    }

    function closeBid(uint _bidId, address _flipper, address _joinAddr) public {
        bytes32 ilk = Join(_joinAddr).ilk();

        Flipper(_flipper).deal(_bidId);
        uint amount = Vat(VAT_ADDRESS).gem(ilk, address(this));

        Vat(VAT_ADDRESS).hope(_joinAddr);
        Gem(_joinAddr).exit(msg.sender, amount);
    }

    function exitCollateral(address _joinAddr) public {
        bytes32 ilk = Join(_joinAddr).ilk();

        uint amount = Vat(VAT_ADDRESS).gem(ilk, address(this));

        Vat(VAT_ADDRESS).hope(_joinAddr);
        Gem(_joinAddr).exit(msg.sender, amount);
    }

    function exitDai() public {
        uint amount = Vat(VAT_ADDRESS).dai(address(this)) / (10**27);

        Vat(VAT_ADDRESS).hope(DAI_JOIN);
        Gem(DAI_JOIN).exit(msg.sender, amount);
    }

    function withdrawToken(address _token) public {
        uint balance = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(msg.sender, balance);
    }

    function withdrawEth() public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function joinDai(uint _amount) internal {
        uint amountInVat = Vat(VAT_ADDRESS).dai(address(this)) / (10**27);

        if (_amount > amountInVat) {
            uint amountDiff = (_amount - amountInVat) + 1;

            ERC20(DAI_ADDRESS).transferFrom(msg.sender, address(this), amountDiff);
            ERC20(DAI_ADDRESS).approve(DAI_JOIN, amountDiff);
            Join(DAI_JOIN).join(address(this), amountDiff);
        }
    }
}