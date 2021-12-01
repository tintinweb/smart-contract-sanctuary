pragma solidity ^0.8.0;
import './IReserve.sol';
import "./IERC20.sol";


contract Exchange {
    address public owner;
    bool public isTradable;
    mapping(address => IReserve) public reserves;
    mapping(address => address) public reserveAddresses;

    constructor () {
        owner = msg.sender;
    } 

    function addReserve(address _reserve, address _token, bool _isAdd) public onlyOwner {
        IReserve reserveSC = IReserve(_reserve);
        if(_isAdd){
            reserves[_token] = reserveSC;
            reserveAddresses[_token] = _reserve;
            ERC20(_token).approve(_reserve, 10**(50+18));     
            reserveSC.setReserveTrable();       
        }else{
            delete reserves[_token];
            delete reserveAddresses[_token];
        }
    }

    //Remember _srcAmount is the amount of _srcToken
    function getExchangeRate(address _srcToken, address _destToken, uint256 _srcAmount) public view returns(uint256) {
        address eth = address(0);
        if(_srcToken == _destToken){
            revert('Irrational transaction!');
        }
        //Buy
        if(_srcToken == eth && _destToken != eth){
            if(reserveAddresses[_destToken] == address(0)){
                return 0;
            }
            return reserves[_destToken].getExchangeRate(true, _srcAmount);
        }
        //Sell
        else if(_srcToken != eth && _destToken == eth){
            if(reserveAddresses[_srcToken] == address(0)){
                return 0;
            }
            return reserves[_srcToken].getExchangeRate(false, _srcAmount);
        }
        //Exchange between 2 ERC20
        else{
            if(reserveAddresses[_srcToken] == address(0) || reserveAddresses[_destToken] == address(0)){
                return 0;
            }
            uint256 budget = reserves[_srcToken].getExchangeRate(false, _srcAmount);
            return reserves[_destToken].getExchangeRate(true, budget);
        }
    }

    //Remember that exchange will be call with ETH value, so 
    //in this function, we should not call the transfer method 
    function exchange(address _srcToken, address _destToken, uint256 _srcAmount) public payable {
        address eth = address(0);        
        uint256 exchangeAmount = getExchangeRate(_srcToken, _destToken, _srcAmount);
        
        //Exchange amount = 0 => out of fund
        //Exchange amount = -1 => reserves haven't been added
        //Exchange amount = 1 => _srcToken = _desToken 
        if(exchangeAmount == 0){
            revert('Reserve is run out of fund!');
        }

        //Sell inclues (happens when user try to exchange ER20-ETH or exchange ER20-ER20)
        //Returns: ETH transfering to this SC will be included in this phase
        if(_srcToken != eth){
            //Sell token to _srcToken
            if(ERC20(_srcToken).balanceOf(msg.sender) < _srcAmount){
                revert('Buyer does not have enough ERC20!');
            }
            //Allowance Check
            if(ERC20(_srcToken).allowance(msg.sender, address(this)) < _srcAmount){
                revert('You have not allowed us to spend this much coin!');
            }
            //Get ERC20 from user
            ERC20(_srcToken).transferFrom(msg.sender, address(this), _srcAmount);
            //Call exchange to get back ETH
            reserves[_srcToken].exchange(false, _srcAmount);            
            //If true this refer to a selling, if not this refer to a ERC20 swap
            if(_destToken == eth){
                if(address(this).balance < exchangeAmount){
                    revert('Exchange have not received ETH from Reserve!');
                }
                //Send ETH to user
                payable(msg.sender).transfer(exchangeAmount);
            }else{
                //Calculate budget get when sell _srcAmount of ER20
                uint256 budget = reserves[_srcToken].getExchangeRate(false, _srcAmount);
                //SECOND: Buy token from destToken (send ETH and call exchange)
                if(address(this).balance < budget){
                    revert('Exchange have not received potential ETH after selling srcToken!');
                }
                reserves[_destToken].exchange{value: budget}(true, budget);
                //Send destToken to user
                if(ERC20(_destToken).balanceOf(address(this)) < exchangeAmount){
                    revert('Exchange have not received ERC20 from Reserve!');
                }
                ERC20(_destToken).transfer(msg.sender, exchangeAmount);
            }
        }

        //Buy ERC20
        if(_srcToken == eth && _destToken != eth){
            //Check if user send enought ETH to SC
            if(msg.value != _srcAmount){
                revert('Buyer does not send enough ETH!');
            }
            
            //Check if ETH in this SC is able to make exchange
            if(address(this).balance < _srcAmount){
                revert('Exchange does not have enough ETH!');
            }
            //Send eth and get deskToken from dest reserve
            reserves[_destToken].exchange{value: _srcAmount}(true, _srcAmount);
            //Send deskToken to user
            if(ERC20(_destToken).balanceOf(address(this)) < exchangeAmount){
                revert('Exchange have not received ERC20 from Reserve!');
            }
            ERC20(_destToken).transfer(msg.sender, exchangeAmount);
        }
    } 

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    receive() external payable {}

    fallback() external payable {}   
}