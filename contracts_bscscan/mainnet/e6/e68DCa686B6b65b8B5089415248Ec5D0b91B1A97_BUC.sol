/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.4;

//main contract
contract BUC {
    //ERC20

    // Public variables of the token
    string public name = "Basic Univesal Coin";
    string public symbol = "BUC";
    uint256 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 private TS = 10**9 * 10**(decimals);

    // maps the address with its balance
    mapping(address => uint256) private balance;

    // maps the address with its allowance
    mapping(address => mapping(address => uint256)) private allow;

    //storing time of latest tx for each address, needed this for mine function
    mapping(address => uint256) private time;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    //emits total supply whenever its updated
    event Tsupply(uint256 indexed _tsup,uint256 indexed _time);

    //time stamp of each day begining
    uint256 tstamp;

    //total share ,that is 100% in the economy with (decimals) decimal places
    uint256 Tshare = 100 * 10**(decimals);

    /*
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        balance[msg.sender] = Tshare; // Give the creator all stake(100%)
        tstamp = now;
    }

    //function to return total supply
    function totalSupply() public view returns (uint256) {
        return TS;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return (balance[_account] * TS) / (10**20);
    }
    
    //function to return share of the address
    function yourShare(address _account) public view returns(uint256){
        return balance[_account];
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allow[_owner][_spender];
    }

    /*
     * Internal transfer, only can be called by this contract
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 _val;

        //converting value to share
        _val = ((_value * ((10**(decimals)) * 100)) / TS);

        //checking for 0 tranfer
        require(_val != 0, "your account is empty");

        // Check if the sender has enough stake
        require(balance[_from] >= _val, "insuffiecient balance");

        // Check for overflows
        require(balance[_to] + _val >= balance[_to]);

        //updating time of their latest transaction
        time[msg.sender] = now;

        //calling velocity update avg velocity
        velocity(_value);

        // Subtract from the sender
        balance[_from] -= _val;

        // Add the same to the recipient
        balance[_to] += _val;

        //cleaning dust accounts
        if (balance[_from] < 100) {
            balance[_to] += balance[_from];
            delete balance[_from];
        }

        emit Transfer(_from, _to, _value);
    }

    /*
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

    /*
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
        require(_value <= allow[_from][msg.sender]); // Check allow
        allow[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /*
     * Set allow for other address
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
        allow[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //traded volume in one day
    uint256 public supply;
    
    //declaring target velocity
    uint256 targetVelocity = 10**(decimals-2);

    //declaring ideal constant
    uint256 public rateOfChnage = 6;
    

    function velocity(uint256 _value) internal {
        if (now - tstamp < 1 days) {
            //stores that days trade volume
            supply += _value;
        } else if (now - tstamp >= 1 days) {
            tstamp = now;
            
            supply += _value;
            
             //velocity of one day
            uint256 Velocity;
            
            //calculating Velocity of that day
            Velocity = ((supply * 10**(decimals)) / TS);

            //Initializes supply to 0
            supply = 0;

            //updating TS
            if (Velocity > targetVelocity) {
                TS += ((rateOfChnage * TS) / 10**5);
                emit Tsupply(TS,now);
            } else {
                uint256 uSupply = (TS - ((rateOfChnage * TS) / 10**5));
                if (uSupply > (10**9 * 10**(decimals))) {
                    TS = uSupply;
                    emit Tsupply(TS,now);
                }
                else{
                    TS = 10**9 * 10**(decimals);
                    emit Tsupply(TS,now);
                }
            }
        }
    }
//function to mine tokens ,which would happen if an account dont do any tx for over 2 years
    function mine(address[] memory _lost) external {
        for (uint256 i = 0; i < _lost.length; i++) {
            if ((now - time[_lost[i]]) > 5*52 weeks) {
                balance[msg.sender] += balance[_lost[i]];
                delete balance[_lost[i]];
                delete time[_lost[i]];
            }
        }
    }
}