pragma solidity ^0.4.24;

// PolynomialBonding curve
// Each meme is independent on its own on the eth blockchain
// will implement a good modifier only to kill aka also burn the contracts of duplicates (cheaters)
contract Meme {
    string public ipfsHash;
    address public creator; // aka owner
    uint8 exponent;
    uint256 PRECISION;
    uint256 public totalSupply;
    string public name;
    uint8 public decimals;

    // amount of wei the smart contract holds
    uint256 public poolBalance;

    constructor(string _ipfsHash, address _creator, string _name, uint8 _decimals, uint8 _exponent, uint256 _precision) public {
        ipfsHash = _ipfsHash;
        creator = _creator;
        name = _name;
        decimals = _decimals;        // 18
        exponent = _exponent;        // 1
        PRECISION = _precision;      // experimenting with: 10 billion > 10000000000

        // to reward creators automatically give tokens
        totalSupply = 100 * 1000;
        tokenBalances[msg.sender] = 100 * 1000;
    }

    // tokens owned by each address
    mapping(address => uint256) public tokenBalances;

    // Calculate the integral from 0 to t (number to integrate to)
    function curveIntegral(uint256 _t) internal returns(uint256) {
        uint256 nexp = exponent + 1;
        // calculate integral t^exponent
        return ((PRECISION / nexp) * (_t ** nexp)) / PRECISION;
    }

    // minting new tokens > aka voting
    function mint(uint256 _numTokens) public payable {
        uint256 priceForTokens = getMintingPrice(_numTokens);
        require(msg.value >= priceForTokens, "Not enough value for total price of tokens");

        totalSupply = totalSupply + _numTokens;
        tokenBalances[msg.sender] = tokenBalances[msg.sender] + _numTokens;
        poolBalance = poolBalance + priceForTokens;

        // send back the change
        if (msg.value > priceForTokens) {
            msg.sender.transfer(msg.value - priceForTokens);
        }
    }

    function getMintingPrice(uint256 _numTokens) public view returns(uint256) {
        return curveIntegral(totalSupply + _numTokens) - poolBalance;
    }

    // burning tokens >> eth to return
    function burn(uint256 _numTokens) public {
        require(tokenBalances[msg.sender] >= _numTokens, "Not enough owned tokens to burn");

        uint256 ethToReturn = getBurningReward(_numTokens);

        totalSupply = totalSupply - _numTokens;
        poolBalance = poolBalance - ethToReturn;
        msg.sender.transfer(ethToReturn);
    }

    function getBurningReward(uint256 _numTokens) public view returns(uint256) {
        return poolBalance - (curveIntegral(totalSupply - _numTokens));
    }

    function kill() public {
        // I give myself the ability to kill any contracts, though will only do so with duplicates aka cheaters
        require(msg.sender == address(0x45405DAa47EFf12Bc225ddcAC932Ce5ef965B39b));
        selfdestruct(this);
    }
}

// Factory contract: keeps track of meme for only leaderboard and view purposes
contract MemeRecorder {
    address[] public memeContracts;

    function addMeme(string _ipfsHash, string _name) public {
        Meme newMeme;
        newMeme = new Meme(_ipfsHash, msg.sender, _name, 18, 1, 10000000000);
        memeContracts.push(newMeme);
    }

    function getMemes() public view returns(address[]) {
        return memeContracts;
    }
}