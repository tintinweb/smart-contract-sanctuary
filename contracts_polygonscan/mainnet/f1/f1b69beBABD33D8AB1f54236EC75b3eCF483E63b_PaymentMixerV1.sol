/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


interface PaymentMixerInterface{

    //Customer Wallet
    function TokenPayment(address _tokenAddress, uint256 _tokenAmount) external returns(bool);
    function CoinPayment(uint256 _amount) external payable returns(bool);

    //Parent
    function VerifyCustomerWallet(address _walletAddress) external view returns(bool);
    function TokenSymbolToAddress(string memory _tokenSymbol) external view returns(address);
    function CheckIfTokenEnabled(address _tokenAddress) external view returns(bool);
    function CheckIfAdmin(address _adminAddress) external view returns(bool);
    function ViewAdmin(uint8 _adminIndex) external view returns(address);

    //ERC20 Token
    function symbol() external pure returns (string memory);
    function balanceOf(address _tokenOwner) external view returns (uint256);
    function allowance(address _owner, address _delegate) external view returns (uint256);

    function approve(address _delegateAddress, uint256 _tokenAmount) external returns(bool);
    function transfer(address _receiverAddress, uint256 _tokenAmount) external returns(bool);
    function transferFrom(address _ownerAddress, address _receiverAddress, uint256 _tokenAmount) external returns(bool);
}

contract PaymentMixerV1{
   
    address constant private fiskPayAddress = 0xaBE9255A99fd2EFB4a15fcF375E5D3987E32Ad74;

    PaymentMixerInterface constant private fisk = PaymentMixerInterface(fiskPayAddress);

    struct Slots { 

        string currency;
        uint256 amount;
        address wallet;
        bool available;
        uint256 start;
    }

    Slots[20] private slot;

    uint private mixNo = 0;
    bool private mixing = false;
    bool private enabled = true;

    constructor(){

        for(uint256 i = 0; i < slot.length; i++){

            slot[i].currency = "";
            slot[i].amount = 0;
            slot[i].wallet = address(0);
            slot[i].available = true;
            slot[i].start = 0;
        }
    }

    function CoinPayment(uint256 _amount, address _walletAddress) external payable returns(bool){

        require(enabled, "Mixer disabled");
        require(_amount == msg.value, "Amount security check errored");
        require(fisk.VerifyCustomerWallet(_walletAddress) == true, "Not a FiskPay wallet");

        mix("Matic", _amount, _walletAddress);
    
        return true;
    }

    function TokenPayment(address _tokenAddress, uint256 _tokenAmount, address _walletAddress) external returns(bool){

        require(enabled, "Mixer disabled");
        require(fisk.CheckIfTokenEnabled(_tokenAddress), "Token not enabled at payment system");
        require(fisk.VerifyCustomerWallet(_walletAddress) == true, "Not a FiskPay wallet");

        PaymentMixerInterface token = PaymentMixerInterface(_tokenAddress);

        if(token.allowance(address(this), _walletAddress) < (_tokenAmount + token.balanceOf(address(this)))){

            token.approve(_walletAddress, 2**256-1);

            if(token.allowance(address(this), _walletAddress) < (_tokenAmount + token.balanceOf(address(this)))){

                revert("Allowance increase failed");
            }
        }

        require(token.allowance(msg.sender, address(this)) >= _tokenAmount, "You must approve the token, before paying");
        require(token.balanceOf(msg.sender) >= _tokenAmount, "Not enough Tokens");

        uint256 previousBlance = token.balanceOf(msg.sender);

        require(token.transferFrom(msg.sender, address(this), _tokenAmount), "Tokens could not be transfered");
        require(previousBlance == (token.balanceOf(msg.sender) + _tokenAmount), "Balance missmatch. Contact a FiskPay developer");

        mix(token.symbol(), _tokenAmount, _walletAddress);

        return true;
    }

    function mix(string memory _symbol, uint256 _amount, address _walletAddress) private returns(bool){

        require(!mixing, "Re-entry prevented");
        mixing = true;
    
        for(uint256 i = 0; i < slot.length; i++){

            if(slot[i].available != true){

                uint256 rnd = random(5, mixNo + i) + 2;

                PaymentMixerInterface sendWallet = PaymentMixerInterface(slot[i].wallet);

                if(slot[i].start > 0){

                    slot[i].start -= 1;
                }
                else if(keccak256(abi.encodePacked("Matic")) == keccak256(abi.encodePacked(slot[i].currency))){

                    if(slot[i].amount > address(this).balance){

                        slot[i].amount = address(this).balance;
                    }
                    
                    uint256 sendAmount = slot[i].amount / rnd;

                    try sendWallet.CoinPayment{value : sendAmount}(sendAmount) returns (bool success){

                        if(success){

                            slot[i].amount -= sendAmount;

                            if(slot[i].amount == 0){

                                slot[i].currency = "";
                                slot[i].amount = 0;
                                slot[i].wallet = address(0);
                                slot[i].available = true;
                                slot[i].start = 0;
                            }
                        }
                    }
                    catch{

                        payable(fisk.ViewAdmin(0)).call{value : slot[i].amount}("");

                        slot[i].currency = "";
                        slot[i].amount = 0;
                        slot[i].wallet = address(0);
                        slot[i].available = true;
                        slot[i].start = 0;
                    }
                }
                else{

                    address tokenAddress = fisk.TokenSymbolToAddress(slot[i].currency);

                    PaymentMixerInterface token = PaymentMixerInterface(tokenAddress);

                    if(slot[i].amount > token.balanceOf(address(this))){

                        slot[i].amount = token.balanceOf(address(this));
                    }

                    uint256 sendAmount = slot[i].amount / rnd;

                    try sendWallet.TokenPayment(tokenAddress, sendAmount) returns (bool success){

                        if(success){

                            slot[i].amount -= sendAmount;

                            if(slot[i].amount == 0){

                                slot[i].currency = "";
                                slot[i].amount = 0;
                                slot[i].wallet = address(0);
                                slot[i].available = true;
                                slot[i].start = 0;
                            }
                        }
                    }
                    catch{

                        try token.transfer(fisk.ViewAdmin(0), slot[i].amount){}
                        catch{}

                        slot[i].currency = "";
                        slot[i].amount = 0;
                        slot[i].wallet = address(0);
                        slot[i].available = true;
                        slot[i].start = 0;
                    }
                }
            }
        }

        uint256 swapPosition = random(slot.length, mixNo);
        uint256 startPosition = swapPosition;

        while(slot[swapPosition].start > 0){

            swapPosition++;

            if(swapPosition >= slot.length){

                swapPosition = 0;
            }

            if(swapPosition == startPosition){
                
                break;
            }
        }

        if(slot[swapPosition].available != true){

            PaymentMixerInterface sendWallet = PaymentMixerInterface(slot[swapPosition].wallet);

            if(keccak256(abi.encodePacked("Matic")) == keccak256(abi.encodePacked(slot[swapPosition].currency))){

                if(slot[swapPosition].amount > address(this).balance){

                    slot[swapPosition].amount = address(this).balance;
                }
                
                try sendWallet.CoinPayment{value : slot[swapPosition].amount}(slot[swapPosition].amount){}
                catch{

                    payable(fisk.ViewAdmin(0)).call{value : slot[swapPosition].amount}("");
                }
            }
            else{

                address tokenAddress = fisk.TokenSymbolToAddress(slot[swapPosition].currency);

                PaymentMixerInterface token = PaymentMixerInterface(tokenAddress);

                if(slot[swapPosition].amount > token.balanceOf(address(this))){

                    slot[swapPosition].amount = token.balanceOf(address(this));
                }

                try sendWallet.TokenPayment(tokenAddress, slot[swapPosition].amount){}
                catch{

                    try token.transfer(fisk.ViewAdmin(0), slot[swapPosition].amount){}
                    catch{}
                }
            }
        }

        slot[swapPosition].currency = _symbol;
        slot[swapPosition].amount = _amount;
        slot[swapPosition].wallet = _walletAddress;
        slot[swapPosition].available = false;
        slot[swapPosition].start = random(4, mixNo*3) + 2;

        mixNo += swapPosition;

        if(mixNo > 2**16){

            mixNo = 0;
        }

        mixing = false;

        return true;
    }

    function random(uint256 _number, uint256 _extra) private view returns(uint256){

        return (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) + _extra) % _number;
    }

    function SetMixerState(bool _enabled) external returns(bool){

        require(fisk.CheckIfAdmin(msg.sender), "Admin function only");
        require(enabled != _enabled);

        enabled = _enabled;
        
        return true;
    }

    function Distribute() external returns(bool){

        require(fisk.CheckIfAdmin(msg.sender), "Admin function only");
        require(!enabled, "Mixer not disabled");

        for(uint256 i = 0; i < slot.length; i++){

            if(slot[i].available != true){

                PaymentMixerInterface sendWallet = PaymentMixerInterface(slot[i].wallet);

                if(keccak256(abi.encodePacked("Matic")) == keccak256(abi.encodePacked(slot[i].currency))){

                    if(slot[i].amount > address(this).balance){

                        slot[i].amount = address(this).balance;
                    }
                    
                    try sendWallet.CoinPayment{value : slot[i].amount}(slot[i].amount){}
                    catch{

                        payable(fisk.ViewAdmin(0)).call{value : slot[i].amount}("");
                    }
                }
                else{

                    address tokenAddress = fisk.TokenSymbolToAddress(slot[i].currency);

                    PaymentMixerInterface token = PaymentMixerInterface(tokenAddress);

                    if(slot[i].amount > token.balanceOf(address(this))){

                        slot[i].amount = token.balanceOf(address(this));
                    }

                    try sendWallet.TokenPayment(tokenAddress, slot[i].amount){}
                    catch{

                        try token.transfer(fisk.ViewAdmin(0), slot[i].amount){}
                        catch{}
                    }
                }

                slot[i].currency = "";
                slot[i].amount = 0;
                slot[i].wallet = address(0);
                slot[i].available = true;
                slot[i].start = 0;
            }
        }

        return true;
    }

    receive() external payable{
        
        revert();
    }

    fallback() external payable{
        
        revert();
    }   
}