pragma solidity =0.8.6;

interface IALGBToken {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function freezeTo(
        address _to,
        uint256 _amount,
        uint64 _until
    ) external;

    function months3() external returns (uint64);

    function months6() external returns (uint64);

    function months9() external returns (uint64);

    function months12() external returns (uint64);

    function months18() external returns (uint64);

    function months24() external returns (uint64);

    function months30() external returns (uint64);
}

contract AlgebraAirDrop {
    address owner;
    IALGBToken ALGBToken;

    uint64 public months3;
    uint64 public months6;
    uint64 public months9;
    uint64 public months12;
    uint64 public months18;
    uint64 public months24;
    uint64 public months30;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }

    function setALGBToken(IALGBToken _token) external onlyOwner{
        ALGBToken = _token;

        months3 = _token.months3();
        months6 = _token.months6();
        months9 = _token.months9();
        months12 = _token.months12();
        months18 = _token.months18();
        months24 = _token.months24();
        months30 = _token.months30();
    }

    function airDrop(address[] calldata accounts, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(accounts.length == amounts.length, "lengths differ");
        for (uint256 i; i < accounts.length; i++) {
            uint256 onePart = amounts[i] / 4;
            ALGBToken.transfer(accounts[i], onePart);
            ALGBToken.freezeTo(accounts[i], onePart, months6);
            ALGBToken.freezeTo(accounts[i], onePart, months9);
            ALGBToken.freezeTo(accounts[i], onePart, months12);
        }
    }

    function advisors(address[] calldata accounts)
        external
        onlyOwner
    {
        require(accounts.length == 5, "wrong amount of advisors");
        for (uint256 i; i < 5; i++) {
            ALGBToken.freezeTo(accounts[i], 1500000 * (10**18), months6);
            ALGBToken.freezeTo(accounts[i], 1500000 * (10**18), months9);
            ALGBToken.freezeTo(accounts[i], 1500000 * (10**18), months12);
            ALGBToken.freezeTo(accounts[i], 1500000 * (10**18), uint64(1635262800));
        }
    }
}