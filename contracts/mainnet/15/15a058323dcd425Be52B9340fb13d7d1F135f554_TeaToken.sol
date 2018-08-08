pragma solidity ^0.4.11;

//defines the contract (this is the entire program basically)

contract TeaToken {
    //Definition section. To the non-devs, define means "tell the compiler this concept exists and if I mention it later this is what im talking about" 

    //please note that define does not mean fill with data, that happens later on. Im merely telling the computer these variables exist so it doesnt get confused later.

    uint256 public pricePreSale = 1000000 wei;                       //this is how much each token costs

    uint256 public priceStage1 = 2000000 wei;         

    uint256 public priceStage2 = 4000000 wei;         

    uint256 tea_tokens;

    mapping(address => uint256) public balanceOf;               //this is used to measure how much money some wallet just sent us

    bool public crowdsaleOpen = true;                               //this is a true-false statement that tells the program whether or not the crowdsale is still going. Unlike the others, this one actually does have data saved to it via the = false;

    string public name = "TeaToken";                             //this is the name of the token, what normies will see in their Ether Wallets

    string public symbol = "TEAT";

    uint256 public decimals = 8;

    uint256 durationInMinutes = 10080;              // one week

    uint256 public totalAmountOfTeatokensCreated = 0;

    uint256 public totalAmountOfWeiCollected = 0;

    uint256 public preSaleDeadline = now + durationInMinutes * 1 minutes;         //how long until the crowdsale ends

    uint256 public icoStage1Deadline = now + (durationInMinutes * 2) * 1 minutes;         //how long until the crowdsale ends

    uint256 deadmanSwitchDeadline = now + (durationInMinutes * 4) * 1 minutes;         //how long until the crowdsale ends

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Payout(address indexed to, uint256 value);

    //How the cost of each token works. There are no floats in ethereum. A float is a decimal place number for the non-devs. So in order to do less than one ether you have to define it in subunits. 1000 finney is one ether, and 1000 szabo is one finney. So 1 finney will buy you 10 TeaTokens, or one ETH will buy you 10,000 TeaTokens. This means one TeaToken during presale will cost exactly 100 szabo.

    //1 szabo is a trillion wei

    //definitions for disbursement

    address address1 = 0xa1288081489C16bA450AfE33D1E1dF97D33c85fC;//prog
    address address2 = 0x2DAAf6754DbE3714C0d46ACe2636eb43671034D6;//undiscolsed
    address address3 = 0x86165fd44C96d4eE1e7038D27301E9804D908f0a;//ariana
    address address4 = 0x18555e00bDAEd991f30e530B47fB1c21F93F0389;//biz
    address address5 = 0xB64BD3310445562802f18e188Bf571D479105029;//potato
    address address6 = 0x925F937721E56d06401FC4D191F411382127Df83;//ugly
    address address7 = 0x13688Dd97616f85A363d715509529cFdfe489663;//architectl
    address address8 = 0xC89dB702363E8a100a4b04fDF41c9Dfee572627B;//johnny
    address address9 = 0xB11b98305e4d55610EB18C480477A6984Aa7f7e2;//thawk
    address address10 = 0xb2Ef8eae3ADdB4E66268b49467eeA64F6cD937cf;//danielt
    address address11 = 0x46e8180a477349013434e191E63f2AFD645fd153;//drschultz
    address address12 = 0xC7b32902a15c02F956F978E9F5A3e43342266bf2;//nos
    address address13 = 0xA0b43B97B66a84F3791DE513cC8a35213325C1Ba;//bigmoney
    address address14 = 0xAEe620D07c16c92A7e8E01C096543048ab591bf9;//dinkin
    

    address[] adds = [address1, address2, address3, address4, address5, address6, address7, address8, address9, address10, address11, address12, address13, address14];
    uint numAddresses = adds.length;
    uint sendValue;

    //controller addresses
    //these are the addresses of programmanon, ariana and bizraeli. We can use these to control the contract.
    address controllerAddress1 = 0x86165fd44C96d4eE1e7038D27301E9804D908f0a;//ari
    address controllerAddress2 = 0xa1288081489C16bA450AfE33D1E1dF97D33c85fC;//prog
    address controllerAddress3 = 0x18555e00bDAEd991f30e530B47fB1c21F93F0389;//biz

    /* The function without name is the default function that is called whenever anyone sends funds to a contract. The keyword payable makes sure that this contract can recieve money. */



    function () payable {



        //if (crowdsaleOpen) throw;     //throw means reject the transaction. This will prevent people from accidentally sending money to a crowdsale that is already closed.
        require(crowdsaleOpen);

        uint256 amount = msg.value;                            //measures how many ETH coins they sent us (the message) and stores it as an integer called "amount"
        //presale

        if (now <= preSaleDeadline){
        tea_tokens = (amount / pricePreSale);  
        //stage 1

        }else if (now <= icoStage1Deadline){
        tea_tokens = (amount / priceStage1);  
        //stage 2
        }else{
        tea_tokens = (amount / priceStage2);                        //calculates their total amount of tokens bought
        }

        totalAmountOfWeiCollected += amount;                        //this keeps track of overall profits collected
        totalAmountOfTeatokensCreated += (tea_tokens/100000000);    //this keeps track of the planetary supply of TEA
        balanceOf[msg.sender] += tea_tokens;                        //this adds the reward to their total.
    }

//this is how we get our money out. It can only be activated after the deadline currently.

    function safeWithdrawal() {

        //this checks to see if the sender is actually authorized to trigger the withdrawl. The sender must be the beneficiary in this case or it wont work.
        //the now >= deadline*3 line acts as a deadman switch, ensuring that anyone in the world can trigger the fund release after the specified time

        require(controllerAddress1 == msg.sender || controllerAddress2 == msg.sender || controllerAddress3 == msg.sender || now >= deadmanSwitchDeadline);
        require(this.balance > 0);

        uint256 sendValue = this.balance / numAddresses;
        for (uint256 i = 0; i<numAddresses; i++){

                //for the very final address, send the entire remaining balance instead of the divisor. This is to prevent remainders being left behind.

                if (i == numAddresses-1){

                Payout(adds[i], this.balance);

                if (adds[i].send(this.balance)){}

                }
                else Payout(adds[i], sendValue);
                if (adds[i].send(sendValue)){}
            }

    }

    //this is used to turn off the crowdsale during stage 3. It can also be used to shut down all crowdsales permanently at any stage. It ends the ICO no matter what.



    function endCrowdsale() {
        //this checks to see if the sender is actually authorized to trigger the withdrawl. The sender must be the beneficiary in this case or it wont work.

        require(controllerAddress1 == msg.sender || controllerAddress2 == msg.sender || controllerAddress3 == msg.sender || now >= deadmanSwitchDeadline);
        //shuts down the crowdsale
        crowdsaleOpen = false;
    }
    /* Allows users to send tokens to each other, to act as money */
    //this is the part of the program that allows exchange between the normies. 
    //This has nothing to do with the actual contract execution, this is so people can trade it back and fourth with each other and exchanges.
    //Without this section the TeaTokens would be trapped in their account forever, unable to move.

    function transfer(address _to, uint256 _value) {

        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough

        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows. If someone sent like 500 googolplex tokens it would actually go back to zero again because of an overflow. Computerized integers can only store so many numbers before they run out of room for more. This prevents that from causing a problem. Fun fact: this shit right here is what caused the Y2K bug everyone was panicking about back in 1999

        balanceOf[msg.sender] -= _value;                     // Subtract from the sender

        balanceOf[_to] += _value;                            // Add the same to the recipient

        /* Notify anyone listening that this transfer took place */
        Transfer(msg.sender, _to, _value);
    }
}