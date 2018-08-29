pragma solidity ^0.4.24;

library CheckOverflows {
    function add(uint256 n1, uint256 n2) internal pure returns(uint256 n3) {
        n3 = n1 + n2;
        require(n3 >= n1);
        return n3;
    }

    function sub(uint256 n1, uint256 n2) internal pure returns(uint256) {
        require(n2 <= n1);
        return n1 - n2;
    }

    function mul(uint256 n1, uint256 n2) internal pure returns(uint256 n3) {
        if (n1 == 0 || n2 == 0) {
            return 0;
        }

        n3 = n1 * n2;
        require(n3 / n1 == n2);
        return n3;
    }

    function div(uint256 n1, uint256 n2) internal pure returns(uint256) {
        return n1 / n2;
    }
}

// PolynomialBonding curve
// Each meme is independent on its own on the eth blockchain
contract Meme {
    string public ipfsHash;
    address public creator; // aka owner
    uint256 exponent;
    uint256 PRECISION;
    uint256 public totalSupply;
    string public name;
    uint256 public decimals;

    // amount of wei the smart contract holds
    uint256 public poolBalance;

    using CheckOverflows for uint256;

    constructor(string _ipfsHash, address _creator, string _name, uint256 _decimals, uint256 _exponent, uint256 _precision) public {
        ipfsHash = _ipfsHash;
        creator = _creator;
        name = _name;
        decimals = _decimals;        // 18
        exponent = _exponent;        // 1
        PRECISION = _precision;      // experimenting with: 10 billion > 10000000000

        // to reward creators automatically give tokens 100 * 1000
        totalSupply = 100000;
        tokenBalances[msg.sender] = 100000;
    }

    // tokens owned by each address
    mapping(address => uint256) public tokenBalances;

    // Calculate the integral from 0 to t (number to integrate to)
    // https://github.com/CryptoAgainstHumanity/crypto-against-humanity/blob/master/ethereum/contracts/WhiteCard.sol#L249
    function curveIntegral(uint256 _t) internal returns(uint256) {
        uint256 nexp = exponent.add(1);
        // calculate integral t^exponent
        return PRECISION.div(nexp).mul(_t ** nexp).div(PRECISION);
    }

    // minting new tokens > aka voting
    function mint(uint256 _numTokens) public payable {
        uint256 priceForTokens = getMintingPrice(_numTokens);
        require(msg.value >= priceForTokens, "Not enough value for total price of tokens");

        totalSupply = totalSupply.add(_numTokens);
        tokenBalances[msg.sender] = tokenBalances[msg.sender].add(_numTokens);
        poolBalance = poolBalance.add(priceForTokens);

        // send back the change
        if (msg.value > priceForTokens) {
            msg.sender.transfer(msg.value.sub(priceForTokens));
        }
    }

    function getMintingPrice(uint256 _numTokens) public view returns(uint256) {
        return curveIntegral(totalSupply.add(_numTokens)).sub(poolBalance);
    }

    // burning tokens >> eth to return
    function burn(uint256 _numTokens) public {
        require(tokenBalances[msg.sender] >= _numTokens, "Not enough owned tokens to burn");

        uint256 ethToReturn = getBurningReward(_numTokens);

        totalSupply = totalSupply.sub(_numTokens);
        poolBalance = poolBalance.sub(ethToReturn);

        // 3% fee go to site creators, the rest to former tokens owner
        uint256 fee = ethToReturn.div(100).mul(3);

        address(0x45405DAa47EFf12Bc225ddcAC932Ce5ef965B39b).transfer(fee);
        msg.sender.transfer(ethToReturn.sub(fee));
    }

    function getBurningReward(uint256 _numTokens) public view returns(uint256) {
        return poolBalance.sub(curveIntegral(totalSupply.sub(_numTokens)));
    }

    function kill() public {
        // I give myself the ability to kill any contracts, though will only do so with duplicates aka cheaters
        require(msg.sender == address(0xE76197fAa1C8c4973087d9d79064d2bb6F940946));
        selfdestruct(this);
    }
}

// Factory contract: keeps track of meme for only leaderboard and view purposes
contract MemeRecorder {
    address[] public memeContracts;

    constructor() public {}

    function addMeme(string _ipfsHash, string _name) public {
        Meme newMeme;
        newMeme = new Meme(_ipfsHash, msg.sender, _name, 18, 1, 10000000000);
        memeContracts.push(newMeme);
    }

    function getMemes() public view returns(address[]) {
        return memeContracts;
    }
}