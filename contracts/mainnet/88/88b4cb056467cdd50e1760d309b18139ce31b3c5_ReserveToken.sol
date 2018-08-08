// Welcome to Reserve Token.
//


pragma solidity ^0.4.0;


contract ReserveToken {

    address public tank; //SBC - The tank of the contract
    uint256 public tankAllowance = 0;
    uint256 public tankOut = 0;
    uint256 public valueOfContract = 0;
    string public name;         //Name of the contract
    string public symbol;       //Symbol of the contract
    uint8 public decimals = 18;      //The amount of decimals

    uint256 public totalSupply; //The current total supply.
    uint256 public maxSupply = uint256(0) - 10; //We let the max amount be the most the variable can handle. well... basically.
    uint256 public tankImposedMax = 100000000000000000000000; //SBC - 10 million maximum tokens at first
    uint256 public priceOfToken;    //The current price of a token
    uint256 public divForSellBack = 2; //SBC - The split for when a sell back occurs
    uint256 public divForTank = 200; //SBC - 20=5%. 100=1% 1000=.1% The amount given to the Abby.
    uint256 public divForPrice = 200; //SBC - The rate in which we grow. 2x this is our possible spread.
    uint256 public divForTransfer = 2; //SBC - The rate in which we grow. 2x this is our possible spread.
    uint256 public firstTTax = 10000; //SBC - The amount added to cost of transfer if firstTTaxAmount
    uint256 public firstTTaxAmount = 10000; //SBC - The sender amount must be greater than this amount.
    uint256 public secondTTax = 20000; //SBC -
    uint256 public secondTTaxAmount = 20000; //SBC
    uint256 public minTokens = 100;     //SBC  - minimum amount of tickets a person may mixssxnt at once
    uint256 public maxTokens = 1000;    //SBC -max amount of tickets a person may mint at once
    uint256 public coinprice; //This is calculated on the fly in the sellprice. This is the last buy price. not the current.

    //Standard Token
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;



    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    function ReserveToken() payable public {
        name = "Reserve Token";
        //Setting the name of the contract
        symbol = "RSRV";
        //Setting the symbol
        tank = msg.sender;
        //setting the tank
        priceOfToken = 1 szabo;
    }

    function MintTokens() public payable {
        //Just some requirements for BuyTokens -- The Tank needs no requirements. (Tank is still subjected to fees)
        address inAddress = msg.sender;
        uint256 inMsgValue = msg.value;

        if (inAddress != tank) {
            require(inMsgValue > 1000); //The minimum money supplied
            require(inMsgValue > priceOfToken * minTokens); //The minimum amount of tokens you can buy
            require(inMsgValue < priceOfToken * maxTokens); //The maximum amount of tokens.
        }


        //Add the incoming tank allowance to tankAllowance
        tankAllowance += (inMsgValue / divForTank);
        //add to the value of contact the incoming value - what the tank got.
        valueOfContract += (inMsgValue - (inMsgValue / divForTank));
        //new coins are equalal to teh new value of contract divided by the current price of token
        uint256 newcoins = ((inMsgValue - (inMsgValue / divForTank)) * 1 ether) / (priceOfToken);



         //Ensure that we dont go over the max the tank has set.
        require(totalSupply + newcoins < maxSupply);
        //Ensure that we don&#39;t go oever the maximum amount of coins.
        require(totalSupply + newcoins < tankImposedMax);

        

        //Update use balance, total supply, price of token.
        totalSupply += newcoins;
        priceOfToken += valueOfContract / (totalSupply / 1 ether) / divForPrice;
        balances[inAddress] += newcoins;
    }

    function BurnAllTokens() public {
        address inAddress = msg.sender;
        uint256 theirBalance = balances[inAddress];
        //Get their balance without any crap code
        require(theirBalance > 0);
        //Make sure that they have enough money to cover this.
        balances[inAddress] = 0;
        //Remove the amount now, for re entry prevention
        coinprice = valueOfContract / (totalSupply / 1 ether);
        //Updating the coin price (buy back price)
        uint256 amountGoingOut = coinprice * (theirBalance / 1 ether); //amount going out in etheruem
        //We convert amount going out to amount without divforTank
        uint256 tankAmount = (amountGoingOut / divForTank); //The amount going to the tank
        amountGoingOut = amountGoingOut - tankAmount; //the new amount for our going out without the tank
        //Amount going out minus theW
        tankAllowance += (tankAmount - (tankAmount / divForSellBack)); //Give
        //Add the the tank allowance, here we are functionally making the coin worth more.
        valueOfContract -= amountGoingOut + (tankAmount / divForSellBack); //VOC = ago - (tankAmount left after tankAllowance)
        //Updating the new value of our contract. what we will have after the transfer
        msg.sender.transfer(amountGoingOut);
        //Transfer the money
        totalSupply -= theirBalance;

    }

    function BurnTokens(uint256 _amount) public {
        address inAddress = msg.sender;
        uint256 theirBalance = balances[inAddress];
        //Get their balance without any crap code
        require(_amount <= theirBalance);
        //Make sure that they have enough money to cover this.
        balances[inAddress] -= _amount;
        //Remove the amount now, for re entry prevention
        coinprice = valueOfContract / (totalSupply / 1 ether);
        //Updating the coin price (buy back price)
        uint256 amountGoingOut = coinprice * (_amount / 1 ether); //amount going out in etheruem
        //We convert amount going out to amount without divforTank
        uint256 tankAmount = (amountGoingOut / divForTank); //The amount going to the tank
        amountGoingOut = amountGoingOut - tankAmount; //the new amount for our going out without the tank
        //Amount going out minus theW
        tankAllowance += (tankAmount - (tankAmount / divForSellBack)); //Give
        //Add the the tank allowance, here we are functionally making the coin worth more.
        valueOfContract -= amountGoingOut + (tankAmount / divForSellBack); //VOC = ago - (tankAmount left after tankAllowance)
        //Updating the new value of our contract. what we will have after the transfer
        msg.sender.transfer(amountGoingOut);
        //Transfer the money
        totalSupply -= _amount;

    }

    function CurrentCoinPrice() view public returns (uint256) {
        uint256 amountGoingOut = valueOfContract / (totalSupply / 1 ether);
        //We convert amount going out to amount without divforTank
        uint256 tankAmount = (amountGoingOut / divForTank); //The amount going to the tank
        return amountGoingOut - tankAmount; //the new amount for our going out without the tank
    }


    function TankWithdrawSome(uint256 _amount) public {
        address inAddress = msg.sender;
        require(inAddress == tank);
        //Require person to be the tank

        //if our allowance is greater than the value of the contract then the contract must be empty.
        if (tankAllowance < valueOfContract) {
            require(_amount <= tankAllowance - tankOut);
        }

        //Require the amount to be less than the amount for tank0.

        tankOut += _amount;
        //Adding in new tank withdraw.
        tank.transfer(_amount);
        //transfering amount to tank&#39;s balance.
    }

    //This is an ethereum withdraw for the tank.
    function TankWithdrawAll() public {
        address inAddress = msg.sender;
        require(inAddress == tank);
        //Require person to be the tank

        //if our allowance is greater than the value of the contract then the contract must be empty.
        if (tankAllowance < valueOfContract) {
            require(tankAllowance - tankOut > 0); //Tank allowance - tankout = whats left for tank. and it must be over zero
        }

        //Require the amount to be less than the amount for tank0.

        tankOut += tankAllowance - tankOut; //We give whats left to our tankout makeing whats left zero. so tank cant double withdraw.
        //Adding in new tank withdraw.
        tank.transfer(tankAllowance - tankOut);
        //transfering amount to tank&#39;s balance.
    }





    function TankDeposit() payable public {
        address inAddress = msg.sender;
        uint256 inValue = msg.value;

        require(inAddress == tank);
        //require the person to be a the tank

        if (inValue < tankOut) {
            tankOut -= inValue;
            // We cant underflow here because it has to be less.
        }
        else
        {
            //Add the excess to the contract value
            valueOfContract += (inValue - tankOut) * 1 ether;
            //We DO NOT INCREASE ALLOWANCE, we only allow the tank to go to zero.
            tankOut = 0;

        }
    }


    // What is the balance of a particular account?
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFee(uint256 _amount) view internal returns (uint256){
        //If Amount is above the tax amount return the tax
        if (_amount > secondTTaxAmount)
            return secondTTax;

        if (_amount > firstTTaxAmount)
            return firstTTax;
    }

    // Transfer the balance from tank&#39;s account to another account
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        //variables we are working with.
        uint256 fromBalance = balances[msg.sender];
        uint256 toBalance = balances[_to];
        uint256 tFee = transferFee(_amount);


        //Require the balance be greater than the amount + fee
        require(fromBalance >= _amount + tFee);
        //Require the amount ot be greater than 0.
        require(_amount > 0);
        //Require the toBalance to be greater than the current amount. w
        require(toBalance + _amount > toBalance);

        balances[msg.sender] -= _amount + tFee;
        balances[_to] += _amount;
        balances[tank] += tFee / divForTransfer;
        totalSupply -= tFee - (tFee / divForTransfer);

        emit Transfer(msg.sender, _to, _amount);
        //Create Event

        return true;
    }




    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        uint256 fromBalance = balances[_from];  //The current balance of from
        uint256 toBalance = balances[_to];      //The current blance for to
        uint256 tFee = transferFee(_amount);    //The transaction fee that will be accociated with this transaction

        //Require the from balance to have more than the amount they want to send + the current fee
        require(fromBalance >= _amount + tFee);
        //Require the allowed balance to be greater than that amount as well.
        require(allowed[_from][msg.sender] >= _amount + tFee);
        //Require the current amount to be greater than 0.
        require(_amount > 0);
        //Require the to balance to gain an amount. protect against under and over flows
        require(toBalance + _amount > toBalance);

        //Update from balance, allowed balance, to balance, tank balance, total supply. create Transfer event.
        balances[_from] -= _amount + tFee;
        allowed[_from][msg.sender] -= _amount + tFee;
        balances[_to] += _amount;
        balances[tank] += tFee / divForTransfer;
        totalSupply -= tFee - (tFee / divForTransfer);
        emit Transfer(_from, _to, _amount);

        return true;
    }



    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }



    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     function GrabUnallocatedValue() public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         //Sometimes someone sends money straight to the contract but that isn&#39;t recorded in the value of teh contract.
         //So here we allow tank to withdraw those extra funds
         address walletaddress = this;
         if (walletaddress.balance * 1 ether > valueOfContract) {
            tank.transfer(walletaddress.balance - (valueOfContract / 1 ether));
         }
    }


    function TankTransfer(address _NewTank) public {
        address inAddress = msg.sender;
        require(inAddress == tank);
        tank = _NewTank;
    }

    function SettankImposedMax(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         tankImposedMax = _input;
    }

    function SetdivForSellBack(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         divForSellBack = _input;
    }

    function SetdivForTank(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         divForTank = _input;
    }

    function SetdivForPrice(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         divForPrice = _input;
    }

    function SetfirstTTax(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         firstTTax = _input;
    }

    function SetfirstTTaxAmount(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         firstTTaxAmount = _input;
    }

    function SetsecondTTax(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         secondTTax = _input;
    }

    function SetsecondTTaxAmount(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         secondTTaxAmount = _input;
    }

    function SetminTokens(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         minTokens = _input;
    }

    function SetmaxTokens(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         maxTokens = _input;
    }

    function SetdivForTransfer(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         divForTransfer = _input;
    }



}