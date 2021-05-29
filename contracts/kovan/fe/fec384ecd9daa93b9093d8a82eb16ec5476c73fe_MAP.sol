/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

//SPDX-License-Identifier: MIT;

pragma solidity >=0.4.22 <0.7.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MAP {
    //ERC20

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        decimals = 18;
        totalSupply = 1000000000000000 * 10**uint256(decimals); // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply; // Give the creator all initial tokens
        name = "OhMyGodCoin"; // Set the name for display purposes
        symbol = "OMGC";
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send '_value' tokens to '_to' from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send '_value' tokens to '_to' on behalf of '_from'
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows '_spender' to spend no more than '_value' tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //BANK and ERC721

    // mapping (address => uint256) public balanceBank;

    //mapping for owner of token
    mapping(uint256 => address) public token;

    //number of token an address holds
    mapping(address => uint256) public tokenNo;

    //token data is is mapped with token id
    mapping(uint256 => TokenData) public data;

    //tokenIDs
    uint256 private cmap;

    //total tokens deposited into bank
    uint256 private tokenInBank;

    //inflation percentage
    uint256 private inflation;

    //token data
    struct TokenData {
        uint256 tokenId;
        uint256 time;
        uint256 holdings;
        uint256 interest;
    }

    function deposit(uint256 _value) public {
        require(
            _value <= balanceOf[msg.sender],
            "no enough funds in ur wallet"
        );

        //subs tokens from user wallet
        balanceOf[msg.sender] -= _value;

        //adds tokens to cmap holdings
        data[cmap].holdings = _value;

        //adds tokens to total bank holdings
        tokenInBank += _value;

        //finds interest %
        inflation =
            ((totalSupply - tokenInBank) * 100 * 1000000) /
            (totalSupply);

        //maps cmap token to the user who deposited tokens
        token[cmap] = msg.sender;

        //stores tokenId
        data[cmap].tokenId = cmap;

        //storing time of the deposit
        data[cmap].time = now;

        //storing interest rate at that moment
        data[cmap].interest = inflation;

        //incrementing tokenid
        cmap++;

        //incrementing number of tokens held by the depositor
        tokenNo[msg.sender]++;
    }

    function withdraw(uint256 _tokenId) public {
        require(
            token[_tokenId] == msg.sender,
            "this token dont belongs to you"
        );

        //updating total tokens in bank
        tokenInBank -= data[_tokenId].holdings;

        //calculating interest amount;
        uint256 interestAmount =
            ((data[_tokenId].holdings * data[_tokenId].interest) *
                (now - data[_tokenId].time)) / (100 * 31536000 * 1000000);

        //transfering tokens to users wallet
        balanceOf[msg.sender] += (data[_tokenId].holdings + interestAmount);

        //totalSupply Update
        totalSupply += interestAmount;

        //buring cmap token
        token[_tokenId] = address(0x0);

        //updating number of cmap tokens held by the user
        tokenNo[msg.sender]--;
    }

    function transferCmap(address _id, uint256 _tokenId) public {
        require(token[_tokenId] == msg.sender, "This token dont belong to you");

        //token tranfered to said address
        token[_tokenId] = _id;

        //updating token number for both addresses
        tokenNo[msg.sender]--;
        tokenNo[_id]++;
    }
}