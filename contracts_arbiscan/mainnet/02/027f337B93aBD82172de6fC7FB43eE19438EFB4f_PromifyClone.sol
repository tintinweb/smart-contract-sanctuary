// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PromifyArbitrum.sol";
import "./CloneFactory.sol";
import "./Ownable.sol";


contract PromifyClone is Ownable, CloneFactory {

  address public libraryAddress;

  event PromifyCreated(address newThingAddress);

  function setLibraryAddress(address _libraryAddress) public onlyOwner {
    libraryAddress = _libraryAddress;
  }

  function createThing(string memory name, string memory symbol, address addressPROM, uint256 starAllo, address celebrityAddress, address _DAO) public onlyOwner {
    address clone = createClone(libraryAddress);
    PromifyArbitrum(clone).initialize(name, symbol, addressPROM, starAllo, celebrityAddress, _DAO);
    emit PromifyCreated(clone);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./PRBMathUD60x18.sol";

/**
  @title Promify Celebrity token contract with integrated swapping economic system.
  Economist Dmitry Vizhnitsky
  @author Gosha Skryuchenkov @ Prometeus Labs

  This contract is used when deploying Celebrity Token.
  Celeberity Token has 10 decimals.
  Economic system for token price ratio growth is designed specifically for this contract.
  Economic system is described at https://promify.io/whitepaper
  
  Contract is written due to high complexity of calculations they had be done in binary form. 
  PRBMath library is used as a tool that allows binary calculations.
*/


contract PromifyArbitrum is ERC20Upgradeable {
    uint256 public starSupply;
    uint256 public starRetrieved;
    uint256 public supplySold;
    uint256 public starShare;
    uint256 public promIn;
    uint256 public highestSoldPoint;
    uint256 public scaleFactor = 10**8;
    uint256 public reserve = 100000000000000000;
    uint256 public curve3S0;
    uint256 public accessTimes;
    bool public curveState;
    address public PROM;
    address public starAddress;
    address public DAO;
    
    mapping (address => uint256) public soldInDay;
    mapping (address => uint256) public soldLastTime;
    
    
    event BuyEvent(address caller, address reciever, uint256 amount);
    event SellEvent(address caller, address supporter, address reciever, uint256 amountCC, uint256 amountPROM);
    event LatestPrice(uint256 amount);
    event StarAirdrop(uint amount);
    event CoinCreation(string name, string symbol, address addressPROM, uint256 starAllo, address celebrityAddress);


	/**
     @param name The name of the new CC token.
     @param symbol The symbol of the new CC token.
     @param addressPROM The Address of PROM token, used for swapping CC tokens.
     @param starAllo The percentage of CC token total supply that Celebrity allocated to oneself.
     @param celebrityAddress The address that Celebrity Supply is linked to.
     */
	function initialize(string memory name, string memory symbol, address addressPROM, uint256 starAllo, address celebrityAddress, address _DAO) initializer external {
        require(starAllo <= 15, "Celebrity percentage is too big");
        __ERC20_init(name, symbol);
        uint256 supply = 100000 * (10 ** 10);
        _mint(address(this), supply);
        starShare = starAllo;
        starSupply = supply * starShare / 100;
        PROM = addressPROM;
        starAddress = celebrityAddress;
        DAO = _DAO;
        emit CoinCreation(name, symbol, addressPROM, starAllo, celebrityAddress);     
	}
	
	function updateVariables() public {
	    require(accessTimes == 0, "Accessed already");
	    scaleFactor = 10**8;
	    reserve = 100000000000000000;
	    accessTimes = 1;
	}
	    
  function decimals() public pure override returns (uint8) {
		return 10;
	}
    
  /**
     @param supporter The address that sells CC token and receives PROM token
     @param amount The amount of CC token that is getting sold
     
     This method allows to swap CC token to receive PROM using designated economic system
     This method checks user's 17280 blocks cap which is floating and calculated at the time transaction is mined
     This method chooses which curve should be used for calculations at the time transaction is mined
     This method transfers PROM from contract instance and transfers CC token to contract instance from "supporter"
     
     More information about selling curves and economic system may be found at:
     https://promify.io/whitepaper
     */
    function sellCC(address supporter, address reciever, uint amount) external {
      if (msg.sender != supporter) {
        require(msg.sender == DAO, "Access Denied");
      }
        uint256 amt;
        uint256 latestPrice;
        uint256 stateCheck;
        if (curveState) {
            amt = VSpecial(amount);
            } else if (supplySold < amount) {
                stateCheck = VSpecial2(amount);
                amt = stateCheck + promIn;
                curve3S0 = starSupply - (amount - supplySold);
            }
            else if (supplySold - amount > (totalSupply() * (100 - starShare) / 100) * 2 / 10 && curveState == false) {
                amt = V2(amount);
            }
            else if (supplySold <= (totalSupply() * (100 - starShare) / 100) * 2 / 10 && curveState == false) {
                amt = V1(amount);
            }
            else if(curveState == false) {
                amt = V3(amount);
                amt = promIn + amt - (7136248173270400000000 * (100-starShare) / 100);
            }
            if(supporter != starAddress) {
                if(block.number - 17280 < soldLastTime[supporter]) {
                    require(amt + soldInDay[supporter] <= cap(), "Cap");
                    soldInDay[supporter] = soldInDay[supporter] + amt;
                    } else {
                    soldLastTime[supporter] = block.number;
                    soldInDay[supporter] = amt;
                  }
            }
        if(supplySold <= amount) {
            supplySold = 0;
        } else { 
            supplySold = supplySold - amount;
        }
        if(promIn <= amt) {
            promIn = 0;
        } else {
            promIn = promIn - amt;
        }
        latestPrice = amt / amount;
        if (stateCheck != 0) {
            curveState = true;
            reserve = reserve - stateCheck;
        }
        IERC20Upgradeable(address(this)).transferFrom(supporter, address(this), amount);
        IERC20Upgradeable(PROM).transfer(reciever, amt);
        emit SellEvent(msg.sender, supporter, reciever, amount, amt);
        emit LatestPrice(latestPrice);
        
    }
    
    /**
     @param supporter The address that sends PROM token and recieves CC token
     @param amount The amount of PROM token that is getting sent
     
     This method allows to swap PROM token to recieve CC token using designated economic system
     This method chooses which curve should be used for calculations at the time transaction is mined
     This method transfers CC from contract instance and transfers PROM token to contract instance from transaction caller
     
     More information about buying curves and economic system may be found at:
     https://promify.io/whitepaper
     */
        
    function buyCC(uint256 amount, address supporter) external {
        uint256 amt;
        if (promIn + amount <= 71362481732704000000 * (100-starShare) && curveState == false) {
            amt = S1(amount) - supplySold;
        }
        else if (supplySold > (totalSupply() - starSupply) * 2 / 10 && curveState == false) {
            amt = S2(amount) - supplySold;
        }
        else if(curveState == false) {
            amt = S3(amount) - supplySold;
        }
        if (curveState) {
            if (amount + reserve <= 100000000000000000) {
                curve3S0 = SSpecial(amount);
                amt = curve3S0 - supplySold;
            }
             else if (promIn + amount <= 71362481732704000000 * (100-starShare)) { 
                amt = S1(amount) + starSupply - curve3S0;
                curveState = false;
                reserve = 100000000000000000;
            } else {
                amt = S3(amount) + starSupply - curve3S0;
                curveState = false;
                reserve = 100000000000000000;
            }
        }
        require(totalSupply() - supplySold - amt >= starSupply, "Curve 0");
        uint256 latestPrice = amount / amt;
        supplySold = supplySold + amt;
        promIn = promIn + amount;
        if(highestSoldPoint < supplySold) {
            highestSoldPoint = supplySold;
        }
        IERC20Upgradeable(PROM).transferFrom(msg.sender, address(this), amount);
        IERC20Upgradeable(address(this)).transfer(supporter, amt);
        emit BuyEvent(msg.sender, supporter, amount);
        emit LatestPrice(latestPrice);
    }
    
    /**
    This method allows to send 10% of Celebrity Supply to "starAddress"
    This method can be called once for every 4% of Total supply(excluding star Supply) that's bought out of the Curve up to 40%.
     */
    function transferToStar() external {
        uint256 amount = starSupply / 10;
        require(starRetrieved + amount <= starSupply, "Retrieved all");
        uint256 eligbleParts = highestSoldPoint * 100 / (totalSupply() - starSupply) / 4;
        uint256 eligbleTime = 0;
        for (uint256 i = 0; i < eligbleParts && i < 10; ++i) {
        eligbleTime = eligbleTime + 1;
        }
        require(starRetrieved + amount <= eligbleTime * starSupply / 10, "Not yet");
        starRetrieved = starRetrieved + amount;
        IERC20Upgradeable(address(this)).transfer(starAddress, amount);
        emit StarAirdrop(amount);
    }

    /**
     @param amount The amount of CC token that is getting sold
     
     Internal method that calculates selling price for Curve 1
     More information about buying curves and economic system may be found at:
     https://promify.io/whitepaper 
     */
    function V1(uint256 amount) public view returns (uint256 result) {
        PRBMath.UD60x18 memory _a = PRBMathUD60x18.fromUint(a());
        _a = PRBMathUD60x18.mul(_a, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _amount = PRBMathUD60x18.fromUint(amount);
        PRBMath.UD60x18 memory _S0 = PRBMathUD60x18.fromUint(supplySold);
        PRBMath.UD60x18 memory _S1 = PRBMathUD60x18.sub(_S0, _amount); 
        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(scaleFactor));
        _S1 = PRBMathUD60x18.mul(_S1, PRBMathUD60x18.fromUint(scaleFactor));
        
        PRBMath.UD60x18 memory lnNumerator = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerNum = PRBMathUD60x18.mul(PRBMathUD60x18.fromUint(33), _S0); 
        powerNum = PRBMathUD60x18.div(powerNum, PRBMathUD60x18.fromUint(10));
        powerNum = PRBMathUD60x18.div(powerNum, _a); 
        if (PRBMathUD60x18.toUint(powerNum) >= 4) {
          powerNum = PRBMathUD60x18.sub(powerNum, PRBMathUD60x18.fromUint(4)); 
          lnNumerator = PRBMathUD60x18.pow(lnNumerator, powerNum); 
        } else {
          powerNum = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(4), powerNum); 
          lnNumerator = PRBMathUD60x18.pow(lnNumerator, powerNum);
          lnNumerator = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnNumerator);
        }
        lnNumerator = PRBMathUD60x18.add(lnNumerator, PRBMathUD60x18.fromUint(1)); 
        
        
        PRBMath.UD60x18 memory lnDenominator = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerDen = PRBMathUD60x18.mul(PRBMathUD60x18.fromUint(33), _S1); 
         powerDen = PRBMathUD60x18.div(powerDen, PRBMathUD60x18.fromUint(10));
        powerDen = PRBMathUD60x18.div(powerDen, _a);
        if (PRBMathUD60x18.toUint(powerDen) >= 4) {
          powerDen = PRBMathUD60x18.sub(powerDen, PRBMathUD60x18.fromUint(4));
          lnDenominator = PRBMathUD60x18.pow(lnDenominator, powerDen);
        } else {
          powerDen = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(4), powerDen); 
          lnDenominator = PRBMathUD60x18.pow(lnDenominator, powerDen);
          lnDenominator = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnDenominator);
        }
        lnDenominator = PRBMathUD60x18.add(lnDenominator, PRBMathUD60x18.fromUint(1));
        
        PRBMath.UD60x18 memory _result = PRBMathUD60x18.div(lnNumerator, lnDenominator);
        _result = PRBMathUD60x18.ln(_result);
        _result = PRBMathUD60x18.mul(_result, _a);
        _result = PRBMathUD60x18.mul(_result, PRBMathUD60x18.fromUint(125));
        _result = PRBMathUD60x18.div(_result, PRBMathUD60x18.fromUint(330));
        result = PRBMathUD60x18.toUint(_result);
        return result;
    }
    
    /**
     @param amount The amount of CC token that is getting sold
     
     Internal method that calculates selling price for Curve 2
     More information about buying curves and economic system may be found at:
     https://promify.io/whitepaper
     */
    function V2(uint256 amount) public view returns (uint256 result) {
        PRBMath.UD60x18 memory _a = PRBMathUD60x18.fromUint(a());
        _a = PRBMathUD60x18.mul(_a, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _amount = PRBMathUD60x18.fromUint(amount);
        PRBMath.UD60x18 memory _S0 = PRBMathUD60x18.fromUint(supplySold);
        PRBMath.UD60x18 memory _S1 = PRBMathUD60x18.sub(_S0, _amount); 
        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(scaleFactor));
        _S1 = PRBMathUD60x18.mul(_S1, PRBMathUD60x18.fromUint(scaleFactor));
        
        PRBMath.UD60x18 memory lnNumerator = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerNum = PRBMathUD60x18.div(_S0, _a); 
        
        if (PRBMathUD60x18.toUint(powerNum) >= 3) {
          powerNum = PRBMathUD60x18.sub(powerNum, PRBMathUD60x18.fromUint(3));
          lnNumerator = PRBMathUD60x18.pow(lnNumerator, powerNum);
        } else {
          powerNum = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(3), powerNum); 
          lnNumerator = PRBMathUD60x18.pow(lnNumerator, powerNum);
          lnNumerator = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnNumerator);
        }
        lnNumerator = PRBMathUD60x18.add(lnNumerator, PRBMathUD60x18.fromUint(1));
        
        
        PRBMath.UD60x18 memory lnDenominator = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerDen = PRBMathUD60x18.div(_S1, _a);
        if (PRBMathUD60x18.toUint(powerDen) >= 3) {
          powerDen = PRBMathUD60x18.sub(powerDen, PRBMathUD60x18.fromUint(3));
          lnDenominator = PRBMathUD60x18.pow(lnDenominator, powerDen);
        } else {
          powerDen = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(3), powerDen); 
          lnDenominator = PRBMathUD60x18.pow(lnDenominator, powerDen);
          lnDenominator = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnDenominator);
        }
        lnDenominator = PRBMathUD60x18.add(lnDenominator, PRBMathUD60x18.fromUint(1));
        PRBMath.UD60x18 memory _result = PRBMathUD60x18.div(lnNumerator, lnDenominator);
        _result = PRBMathUD60x18.ln(_result);
        _result = PRBMathUD60x18.mul(_result, PRBMathUD60x18.fromUint(5));
        _result = PRBMathUD60x18.mul(_result, _a);
        
        result = PRBMathUD60x18.toUint(_result);
        return result;
    }
    
    /**
     @param amount The amount of PROM token that is getting sent in order to obtain CC token
     
     Internal method that calculates buing price for Curve 1
     More information about buying curves and economic system may be found at:
     https://promify.io/whitepaper
     */
    function S1(uint256 amount) public view returns (uint256 result) {
        PRBMath.UD60x18 memory _a = PRBMathUD60x18.fromUint(a());
        _a = PRBMathUD60x18.mul(_a, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _S0 = PRBMathUD60x18.fromUint(supplySold);
        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(scaleFactor));
        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(125));
        _S0 = PRBMathUD60x18.div(_S0, PRBMathUD60x18.fromUint(100));
        PRBMath.UD60x18 memory _V = PRBMathUD60x18.fromUint(amount);
        
        PRBMath.UD60x18 memory powerFactor1 = PRBMathUD60x18.add(_V, _S0);
        powerFactor1 = PRBMathUD60x18.mul(powerFactor1, PRBMathUD60x18.fromUint(264));
        powerFactor1 = PRBMathUD60x18.div(powerFactor1, PRBMathUD60x18.fromUint(100));
        powerFactor1 = PRBMathUD60x18.div(powerFactor1, _a);
        PRBMath.UD60x18 memory lnInput1 = PRBMathUD60x18.e();
        if (PRBMathUD60x18.toUint(powerFactor1) >= 4) {  
          powerFactor1 = PRBMathUD60x18.sub(powerFactor1, PRBMathUD60x18.fromUint(4));
          lnInput1 = PRBMathUD60x18.pow(lnInput1, powerFactor1);
        } else {
          powerFactor1 = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(4), powerFactor1);
          lnInput1 = PRBMathUD60x18.pow(lnInput1, powerFactor1);
          lnInput1 = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnInput1);
        }

        PRBMath.UD60x18 memory lnInput2 = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerFactor2 = PRBMathUD60x18.mul(_V, PRBMathUD60x18.fromUint(264));
        powerFactor2 = PRBMathUD60x18.div(powerFactor2, PRBMathUD60x18.fromUint(100));
        powerFactor2 = PRBMathUD60x18.div(powerFactor2, _a);
        lnInput2 = PRBMathUD60x18.pow(lnInput2, powerFactor2);
        lnInput2 = PRBMathUD60x18.add(lnInput2, lnInput1);
        lnInput2 = PRBMathUD60x18.sub(lnInput2, PRBMathUD60x18.fromUint(1));
        PRBMath.UD60x18 memory poweredE = PRBMathUD60x18.e();
        poweredE = PRBMathUD60x18.pow(poweredE, PRBMathUD60x18.fromUint(4));
        lnInput2 = PRBMathUD60x18.mul(lnInput2, poweredE);
        
        PRBMath.UD60x18 memory _result = PRBMathUD60x18.ln(lnInput2);
        _result = PRBMathUD60x18.mul(_result, PRBMathUD60x18.fromUint(10));
        _result = PRBMathUD60x18.div(_result, PRBMathUD60x18.fromUint(33));
        _result = PRBMathUD60x18.mul(_result, _a);
        result = PRBMathUD60x18.toUint(_result);
        result = result / scaleFactor;
        
        return result;
    }
    
    /**
     @param amount The amount of PROM token that is getting sent in order to obtain CC token
     
     Internal method that calculates buing price for Curve 2
     More information about buying curves and economic system may be found at:
     https://promify.io/whitepaper
     */
    function S2(uint256 amount) public view returns (uint256 result) {
        PRBMath.UD60x18 memory _a = PRBMathUD60x18.fromUint(a());
        _a = PRBMathUD60x18.mul(_a, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _S0 = PRBMathUD60x18.fromUint(supplySold);
        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _V = PRBMathUD60x18.fromUint(amount);

        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(5));
        PRBMath.UD60x18 memory powerFactor1 = PRBMathUD60x18.add(_V, _S0);
        powerFactor1 = PRBMathUD60x18.mul(powerFactor1, PRBMathUD60x18.fromUint(2));
        powerFactor1 = PRBMathUD60x18.div(powerFactor1, _a);
        powerFactor1 = PRBMathUD60x18.div(powerFactor1, PRBMathUD60x18.fromUint(10));
        PRBMath.UD60x18 memory lnInput1 = PRBMathUD60x18.e();
        if ((PRBMathUD60x18.toUint(powerFactor1) >= 3)) {
            powerFactor1 = PRBMathUD60x18.sub(powerFactor1, PRBMathUD60x18.fromUint(3));
            lnInput1 = PRBMathUD60x18.pow(lnInput1, powerFactor1);
        } else {
          powerFactor1 = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(3), powerFactor1); 
          lnInput1 = PRBMathUD60x18.pow(lnInput1, powerFactor1);
          lnInput1 = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnInput1);
        }
       
        PRBMath.UD60x18 memory lnInput2 = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerFactor2 = PRBMathUD60x18.mul(_V, PRBMathUD60x18.fromUint(2));
        powerFactor2 = PRBMathUD60x18.div(powerFactor2, _a);
        powerFactor2 = PRBMathUD60x18.div(powerFactor2, PRBMathUD60x18.fromUint(10));
        lnInput2 = PRBMathUD60x18.pow(lnInput2, powerFactor2);
        lnInput2 = PRBMathUD60x18.add(lnInput2, lnInput1);
        lnInput2 = PRBMathUD60x18.sub(lnInput2, PRBMathUD60x18.fromUint(1));
        PRBMath.UD60x18 memory poweredE = PRBMathUD60x18.e();
        poweredE = PRBMathUD60x18.pow(poweredE, PRBMathUD60x18.fromUint(3));
        lnInput2 = PRBMathUD60x18.mul(lnInput2, poweredE);
        
        PRBMath.UD60x18 memory _result = PRBMathUD60x18.ln(lnInput2);
        _result = PRBMathUD60x18.mul(_result, _a);
        _result = PRBMathUD60x18.div(_result, PRBMathUD60x18.fromUint(scaleFactor));
        result = PRBMathUD60x18.toUint(_result);
        
        return result;
    }
    
    /**
     @param amount The amount of PROM token that is getting sent in order to obtain CC token
     
     Internal method that calculates buing price for transition of Curve 1 -> Curve 2
     More information about buying curves and economic system may be found at:
     https://promify.io/whitepaper
     */
    function S3(uint256 amount) public view returns (uint256 result) {
        uint256 customSupply = totalSupply() * (100 - starShare) * 2 / 1000;
        uint256 customAmount = amount - (7136248173270400000000 * (100 - starShare) / 100 - promIn);
        PRBMath.UD60x18 memory _a = PRBMathUD60x18.fromUint(a());
        _a = PRBMathUD60x18.mul(_a, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _S0 = PRBMathUD60x18.fromUint(customSupply);
        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _V = PRBMathUD60x18.fromUint(customAmount);

        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(5));
        PRBMath.UD60x18 memory powerFactor1 = PRBMathUD60x18.add(_V, _S0);
        powerFactor1 = PRBMathUD60x18.mul(powerFactor1, PRBMathUD60x18.fromUint(2));
        powerFactor1 = PRBMathUD60x18.div(powerFactor1, _a);
        powerFactor1 = PRBMathUD60x18.div(powerFactor1, PRBMathUD60x18.fromUint(10));
        PRBMath.UD60x18 memory lnInput1 = PRBMathUD60x18.e();
        if ((PRBMathUD60x18.toUint(powerFactor1) >= 3)) {
            powerFactor1 = PRBMathUD60x18.sub(powerFactor1, PRBMathUD60x18.fromUint(3));
            lnInput1 = PRBMathUD60x18.pow(lnInput1, powerFactor1); 
        } else {
          powerFactor1 = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(3), powerFactor1); 
          lnInput1 = PRBMathUD60x18.pow(lnInput1, powerFactor1);
          lnInput1 = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnInput1);
        }
        
         
        PRBMath.UD60x18 memory lnInput2 = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerFactor2 = PRBMathUD60x18.mul(_V, PRBMathUD60x18.fromUint(2));
        powerFactor2 = PRBMathUD60x18.div(powerFactor2, _a);
        powerFactor2 = PRBMathUD60x18.div(powerFactor2, PRBMathUD60x18.fromUint(10));
        lnInput2 = PRBMathUD60x18.pow(lnInput2, powerFactor2);
        lnInput2 = PRBMathUD60x18.add(lnInput2, lnInput1);
        lnInput2 = PRBMathUD60x18.sub(lnInput2, PRBMathUD60x18.fromUint(1));
        PRBMath.UD60x18 memory poweredE = PRBMathUD60x18.e();
        poweredE = PRBMathUD60x18.pow(poweredE, PRBMathUD60x18.fromUint(3));
        lnInput2 = PRBMathUD60x18.mul(lnInput2, poweredE);
        
        PRBMath.UD60x18 memory _result = PRBMathUD60x18.ln(lnInput2);
        _result = PRBMathUD60x18.mul(_result, _a);
        _result = PRBMathUD60x18.div(_result, PRBMathUD60x18.fromUint(scaleFactor));
        result = PRBMathUD60x18.toUint(_result);
        
        return result;
    }
    
    /**
     @param amount The amount of CC token that is getting sold
     
     Internal method that calculates selling price for transition of Curve 1 -> Curve 2
     More information about buying curves and economic system may be found at:
     https://promify.io/whitepaper
     */
    function V3(uint256 amount) public view returns (uint256 result) {
        uint256 customS1 = totalSupply() * (100 - starShare) * 2 / 1000;
        uint256 customSupplySold = supplySold - amount;
        PRBMath.UD60x18 memory _a = PRBMathUD60x18.fromUint(a());
        _a = PRBMathUD60x18.mul(_a, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _S0 = PRBMathUD60x18.fromUint(customSupplySold);
        PRBMath.UD60x18 memory _S1 = PRBMathUD60x18.fromUint(customS1); 
        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(scaleFactor));
        _S1 = PRBMathUD60x18.mul(_S1, PRBMathUD60x18.fromUint(scaleFactor));
        
        
        PRBMath.UD60x18 memory lnNumerator = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerNum = PRBMathUD60x18.mul(PRBMathUD60x18.fromUint(33), _S1); 
        powerNum = PRBMathUD60x18.div(powerNum, PRBMathUD60x18.fromUint(10));
        powerNum = PRBMathUD60x18.div(powerNum, _a); 
        if (PRBMathUD60x18.toUint(powerNum) >= 4) {
          powerNum = PRBMathUD60x18.sub(powerNum, PRBMathUD60x18.fromUint(4)); 
          lnNumerator = PRBMathUD60x18.pow(lnNumerator, powerNum); 
        } else {
          powerNum = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(4), powerNum); 
          lnNumerator = PRBMathUD60x18.pow(lnNumerator, powerNum);
          lnNumerator = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnNumerator);
        }
        lnNumerator = PRBMathUD60x18.add(lnNumerator, PRBMathUD60x18.fromUint(1)); 
        
        
        PRBMath.UD60x18 memory lnDenominator = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerDen = PRBMathUD60x18.mul(PRBMathUD60x18.fromUint(33), _S0); 
         powerDen = PRBMathUD60x18.div(powerDen, PRBMathUD60x18.fromUint(10));
        powerDen = PRBMathUD60x18.div(powerDen, _a);
        if (PRBMathUD60x18.toUint(powerDen) >= 4) {
          powerDen = PRBMathUD60x18.sub(powerDen, PRBMathUD60x18.fromUint(4));
          lnDenominator = PRBMathUD60x18.pow(lnDenominator, powerDen);
        } else {
          powerDen = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(4), powerDen); 
          lnDenominator = PRBMathUD60x18.pow(lnDenominator, powerDen);
          lnDenominator = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnDenominator);
        }
        lnDenominator = PRBMathUD60x18.add(lnDenominator, PRBMathUD60x18.fromUint(1));
        
        PRBMath.UD60x18 memory _result = PRBMathUD60x18.div(lnNumerator, lnDenominator);
        _result = PRBMathUD60x18.ln(_result);
        _result = PRBMathUD60x18.mul(_result, _a);
        _result = PRBMathUD60x18.mul(_result, PRBMathUD60x18.fromUint(125));
        _result = PRBMathUD60x18.div(_result, PRBMathUD60x18.fromUint(330));
        result = PRBMathUD60x18.toUint(_result);
        return result;
    }
    
    /**
     @param amount The amount of CC token that is getting sold 
     
     Internal method that calculates selling price for a special case #1
     More information about buying curves and economic system may be found at:
     https://promify.io/whitepaper
     */
    function VSpecial(uint256 amount) public view returns (uint256 result) {
        PRBMath.UD60x18 memory _a = PRBMathUD60x18.fromUint(a());
        _a = PRBMathUD60x18.mul(_a, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _amount = PRBMathUD60x18.fromUint(amount);
        PRBMath.UD60x18 memory _S1 = PRBMathUD60x18.fromUint(starSupply); 
        PRBMath.UD60x18 memory _S0 = PRBMathUD60x18.sub(_S1, _amount);
        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(scaleFactor));
        _S1 = PRBMathUD60x18.mul(_S1, PRBMathUD60x18.fromUint(scaleFactor));
        
        PRBMath.UD60x18 memory lnNumerator = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerNum = PRBMathUD60x18.mul(PRBMathUD60x18.fromUint(33), _S1);
        powerNum = PRBMathUD60x18.div(powerNum, PRBMathUD60x18.fromUint(10));
        powerNum = PRBMathUD60x18.div(powerNum, _a);
        if (PRBMathUD60x18.toUint(powerNum) >= 14) {
          powerNum = PRBMathUD60x18.sub(powerNum, PRBMathUD60x18.fromUint(14));
          lnNumerator = PRBMathUD60x18.pow(lnNumerator, powerNum);
        } else {
          powerNum = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(14), powerNum); 
          lnNumerator = PRBMathUD60x18.pow(lnNumerator, powerNum);
          lnNumerator = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnNumerator);
        }
        lnNumerator = PRBMathUD60x18.add(lnNumerator, PRBMathUD60x18.fromUint(1));
        
        
        PRBMath.UD60x18 memory lnDenominator = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerDen = PRBMathUD60x18.mul(PRBMathUD60x18.fromUint(33), _S0);
         powerDen = PRBMathUD60x18.div(powerDen, PRBMathUD60x18.fromUint(10));
        powerDen = PRBMathUD60x18.div(powerDen, _a); 
        if (PRBMathUD60x18.toUint(powerDen) >= 14) {
          powerDen = PRBMathUD60x18.sub(powerDen, PRBMathUD60x18.fromUint(14));
          lnDenominator = PRBMathUD60x18.pow(lnDenominator, powerDen);
        } else {
          powerDen = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(14), powerDen); 
          lnDenominator = PRBMathUD60x18.pow(lnDenominator, powerDen);
          lnDenominator = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnDenominator);
        }
        lnDenominator = PRBMathUD60x18.add(lnDenominator, PRBMathUD60x18.fromUint(1));
        
        PRBMath.UD60x18 memory _result = PRBMathUD60x18.div(lnNumerator, lnDenominator);
        _result = PRBMathUD60x18.ln(_result);
        _result = PRBMathUD60x18.mul(_result, _a);
        _result = PRBMathUD60x18.mul(_result, PRBMathUD60x18.fromUint(125));
        _result = PRBMathUD60x18.div(_result, PRBMathUD60x18.fromUint(330));
        result = PRBMathUD60x18.toUint(_result);
        return result;
    }
    
    /**
     @param amount The amount of CC token that is getting sold in order to obtain CC token
     
     Internal method that calculates selling price for a special case #2
     More information about buying curves and economic system may be found at:
     https://promify.io/whitepaper
     */
    function VSpecial2(uint256 amount) public view returns (uint256 result) {
        PRBMath.UD60x18 memory _a = PRBMathUD60x18.fromUint(a());
        _a = PRBMathUD60x18.mul(_a, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _amount = PRBMathUD60x18.fromUint(amount);
        PRBMath.UD60x18 memory _S1 = PRBMathUD60x18.fromUint(starSupply); 
        PRBMath.UD60x18 memory _S0 = PRBMathUD60x18.sub(_amount, PRBMathUD60x18.fromUint(supplySold));
        _S0 = PRBMathUD60x18.sub(_S1, _S0);
        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(scaleFactor));
        _S1 = PRBMathUD60x18.mul(_S1, PRBMathUD60x18.fromUint(scaleFactor));
        
        PRBMath.UD60x18 memory lnNumerator = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerNum = PRBMathUD60x18.mul(PRBMathUD60x18.fromUint(33), _S1);
        powerNum = PRBMathUD60x18.div(powerNum, PRBMathUD60x18.fromUint(10));
        powerNum = PRBMathUD60x18.div(powerNum, _a);
        if (PRBMathUD60x18.toUint(powerNum) >= 14) {
          powerNum = PRBMathUD60x18.sub(powerNum, PRBMathUD60x18.fromUint(14));
          lnNumerator = PRBMathUD60x18.pow(lnNumerator, powerNum);
        } else {
          powerNum = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(14), powerNum); 
          lnNumerator = PRBMathUD60x18.pow(lnNumerator, powerNum);
          lnNumerator = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnNumerator);
        }
        lnNumerator = PRBMathUD60x18.add(lnNumerator, PRBMathUD60x18.fromUint(1));
        
        PRBMath.UD60x18 memory lnDenominator = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerDen = PRBMathUD60x18.mul(PRBMathUD60x18.fromUint(33), _S0); 
        powerDen = PRBMathUD60x18.div(powerDen, PRBMathUD60x18.fromUint(10));
        powerDen = PRBMathUD60x18.div(powerDen, _a);
        if (PRBMathUD60x18.toUint(powerDen) >= 14) {
          powerDen = PRBMathUD60x18.sub(powerDen, PRBMathUD60x18.fromUint(14)); 
          lnDenominator = PRBMathUD60x18.pow(lnDenominator, powerDen);
        } else {
          powerDen = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(14), powerDen); 
          lnDenominator = PRBMathUD60x18.pow(lnDenominator, powerDen);
          lnDenominator = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnDenominator);
        }
        lnDenominator = PRBMathUD60x18.add(lnDenominator, PRBMathUD60x18.fromUint(1));
        
        PRBMath.UD60x18 memory _result = PRBMathUD60x18.div(lnNumerator, lnDenominator);
        _result = PRBMathUD60x18.ln(_result);
        _result = PRBMathUD60x18.mul(_result, _a);
        _result = PRBMathUD60x18.mul(_result, PRBMathUD60x18.fromUint(125));
        _result = PRBMathUD60x18.div(_result, PRBMathUD60x18.fromUint(330));
        result = PRBMathUD60x18.toUint(_result);
        return result;
    }
    
    /**
     @param amount The amount of PROM token that is getting sold in order to obtain CC token
     
     Internal method that calculates buying price for a special case #1
     More information about buying curves and economic system may be found at:
     https://promify.io/whitepaper
     */
    function SSpecial(uint256 amount) public view returns (uint256 result) {
        PRBMath.UD60x18 memory _a = PRBMathUD60x18.fromUint(a());
        _a = PRBMathUD60x18.mul(_a, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _S0 = PRBMathUD60x18.fromUint(curve3S0);
        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(scaleFactor));
        PRBMath.UD60x18 memory _V = PRBMathUD60x18.fromUint(amount);
        _V = PRBMathUD60x18.sub(_V, PRBMathUD60x18.fromUint(promIn));
        _S0 = PRBMathUD60x18.mul(_S0, PRBMathUD60x18.fromUint(125));
        _S0 = PRBMathUD60x18.div(_S0, PRBMathUD60x18.fromUint(100));
        
        PRBMath.UD60x18 memory powerFactor1 = PRBMathUD60x18.add(_V, _S0);
        powerFactor1 = PRBMathUD60x18.mul(powerFactor1, PRBMathUD60x18.fromUint(264));
        powerFactor1 = PRBMathUD60x18.div(powerFactor1, PRBMathUD60x18.fromUint(100));
        powerFactor1 = PRBMathUD60x18.div(powerFactor1, _a);
        PRBMath.UD60x18 memory lnInput1 = PRBMathUD60x18.e();
        if (PRBMathUD60x18.toUint(powerFactor1) >= 14) {  
          powerFactor1 = PRBMathUD60x18.sub(powerFactor1, PRBMathUD60x18.fromUint(14));
          lnInput1 = PRBMathUD60x18.pow(lnInput1, powerFactor1);
        } else {
          powerFactor1 = PRBMathUD60x18.sub(PRBMathUD60x18.fromUint(14), powerFactor1);
          lnInput1 = PRBMathUD60x18.pow(lnInput1, powerFactor1);
          lnInput1 = PRBMathUD60x18.div(PRBMathUD60x18.fromUint(1), lnInput1);
        }

        PRBMath.UD60x18 memory lnInput2 = PRBMathUD60x18.e();
        PRBMath.UD60x18 memory powerFactor2 = PRBMathUD60x18.mul(_V, PRBMathUD60x18.fromUint(264));
        powerFactor2 = PRBMathUD60x18.div(powerFactor2, PRBMathUD60x18.fromUint(100));
        powerFactor2 = PRBMathUD60x18.div(powerFactor2, _a);
        lnInput2 = PRBMathUD60x18.pow(lnInput2, powerFactor2);
        lnInput2 = PRBMathUD60x18.add(lnInput2, lnInput1);
        lnInput2 = PRBMathUD60x18.sub(lnInput2, PRBMathUD60x18.fromUint(1));
        PRBMath.UD60x18 memory poweredE = PRBMathUD60x18.e();
        poweredE = PRBMathUD60x18.pow(poweredE, PRBMathUD60x18.fromUint(14));
        lnInput2 = PRBMathUD60x18.mul(lnInput2, poweredE);
        
        PRBMath.UD60x18 memory _result = PRBMathUD60x18.ln(lnInput2);
        _result = PRBMathUD60x18.mul(_result, PRBMathUD60x18.fromUint(10));
        _result = PRBMathUD60x18.div(_result, PRBMathUD60x18.fromUint(33));
        _result = PRBMathUD60x18.mul(_result, _a);
        result = PRBMathUD60x18.toUint(_result);
        result = result / scaleFactor;
        
        return result;
    }

    function a() public view returns (uint256 _a) {
        _a = (12500 * (10 ** 10) * (100 - starShare) / 100);
        return _a;
    }
    
    function cap() public view returns (uint256 result) {
        result = promIn * 162 * supplySold / (17010 * (supplySold + starSupply));
        if (result >= 5 * (10 ** 18)) {
            return result; 
        } else {
            result = 5 * (10 ** 18);
            return result;
        }
    }
    function updateDAO(address newDAO) public {
        require(msg.sender == DAO, "Access denied");
        DAO = newDAO;
    }
}

pragma solidity ^0.8.0;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math. It works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// STORAGE ///

    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Adds two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @param x The first unsigned 60.18-decimal fixed-point number to add.
    /// @param y The second unsigned 60.18-decimal fixed-point number to add.
    /// @param result The result as an unsigned 59.18 decimal fixed-point number.
    function add(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y) internal pure returns (PRBMath.UD60x18 memory result) {
        unchecked {
            uint256 rValue = x.value + y.value;
            require(rValue >= x.value);
            result = PRBMath.UD60x18({ value: rValue });
        }
    }

    /// @notice Calculates arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an usigned 60.18-decimal fixed-point number.
    function avg(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y) internal pure returns (PRBMath.UD60x18 memory result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            uint256 rValue = (x.value >> 1) + (y.value >> 1) + (x.value & y.value & 1);
            result = PRBMath.UD60x18({ value: rValue });
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        uint256 xValue = x.value;
        require(xValue <= MAX_WHOLE_UD60x18);

        uint256 rValue;
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(xValue, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            rValue := add(xValue, mul(delta, gt(remainder, 0)))
        }
        result = PRBMath.UD60x18({ value: rValue });
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - y cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y) internal pure returns (PRBMath.UD60x18 memory result) {
        result = PRBMath.UD60x18({ value: PRBMath.mulDiv(x.value, SCALE, y.value) });
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (PRBMath.UD60x18 memory result) {
        result = PRBMath.UD60x18({ value: 2718281828459045235 });
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 88.722839111672999628.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        // Without this check, the value passed to "exp2" would be greater than 128e18.
        require(x.value < 88722839111672999628);

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x.value * LOG2_E;
            PRBMath.UD60x18 memory exponent = PRBMath.UD60x18({ value: (doubleScaleProduct + HALF_SCALE) / SCALE });
            result = exp2(exponent);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 128e18 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        // 2**128 doesn't fit within the 128.128-bit format used internally in this function.
        require(x.value < 128e18);

        unchecked {
            // Convert x to the 128.128-bit fixed-point format.
            uint256 x128x128 = (x.value << 128) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 128.128-bit fixed-point number representation.
            result = PRBMath.UD60x18({ value: PRBMath.exp2(x128x128) });
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        uint256 xValue = x.value;
        uint256 rValue;
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(xValue, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            rValue := sub(xValue, mul(remainder, gt(remainder, 0)))
        }
        result = PRBMath.UD60x18({ value: rValue });
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        uint256 xValue = x.value;
        uint256 rValue;
        assembly {
            rValue := mod(xValue, SCALE)
        }
        result = PRBMath.UD60x18({ value: rValue });
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (PRBMath.UD60x18 memory result) {
        unchecked {
            require(x <= MAX_UD60x18 / SCALE);
            result = PRBMath.UD60x18({ value: x * SCALE });
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y) internal pure returns (PRBMath.UD60x18 memory result) {
        if (x.value == 0) {
            return PRBMath.UD60x18({ value: 0 });
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x.value * y.value;
            require(xy / x.value == y.value);

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.UD60x18({ value: PRBMath.sqrt(xy) });
        }
    }

    /// @notice Calculates 1 / x, rounding towards zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = PRBMath.UD60x18({ value: 1e36 / x.value });
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            uint256 rValue = (log2(x).value * SCALE) / LOG2_E;
            result = PRBMath.UD60x18({ value: rValue });
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        uint256 xValue = x.value;
        require(xValue >= SCALE);

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this
        // contract.
        uint256 rValue;

        // prettier-ignore
        assembly {
            switch x
            case 1 { rValue := mul(SCALE, sub(0, 18)) }
            case 10 { rValue := mul(SCALE, sub(1, 18)) }
            case 100 { rValue := mul(SCALE, sub(2, 18)) }
            case 1000 { rValue := mul(SCALE, sub(3, 18)) }
            case 10000 { rValue := mul(SCALE, sub(4, 18)) }
            case 100000 { rValue := mul(SCALE, sub(5, 18)) }
            case 1000000 { rValue := mul(SCALE, sub(6, 18)) }
            case 10000000 { rValue := mul(SCALE, sub(7, 18)) }
            case 100000000 { rValue := mul(SCALE, sub(8, 18)) }
            case 1000000000 { rValue := mul(SCALE, sub(9, 18)) }
            case 10000000000 { rValue := mul(SCALE, sub(10, 18)) }
            case 100000000000 { rValue := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { rValue := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { rValue := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { rValue := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { rValue := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { rValue := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { rValue := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { rValue := 0 }
            case 10000000000000000000 { rValue := SCALE }
            case 100000000000000000000 { rValue := mul(SCALE, 2) }
            case 1000000000000000000000 { rValue := mul(SCALE, 3) }
            case 10000000000000000000000 { rValue := mul(SCALE, 4) }
            case 100000000000000000000000 { rValue := mul(SCALE, 5) }
            case 1000000000000000000000000 { rValue := mul(SCALE, 6) }
            case 10000000000000000000000000 { rValue := mul(SCALE, 7) }
            case 100000000000000000000000000 { rValue := mul(SCALE, 8) }
            case 1000000000000000000000000000 { rValue := mul(SCALE, 9) }
            case 10000000000000000000000000000 { rValue := mul(SCALE, 10) }
            case 100000000000000000000000000000 { rValue := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { rValue := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { rValue := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { rValue := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { rValue := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { rValue := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { rValue := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { rValue := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { rValue := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { rValue := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { rValue := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { rValue := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { rValue := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { rValue := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { rValue := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { rValue := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 59) }
            default {
                rValue := MAX_UD60x18
            }
        }

        if (rValue != MAX_UD60x18) {
            result = PRBMath.UD60x18({ value: rValue });
        } else {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                rValue = (log2(x).value * SCALE) / 3321928094887362347;
                result = PRBMath.UD60x18({ value: rValue });
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        require(x.value >= SCALE);
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x.value / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            uint256 rValue = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x.value >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return PRBMath.UD60x18({ value: rValue });
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    rValue += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result = PRBMath.UD60x18({ value: rValue });
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mul(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y) internal pure returns (PRBMath.UD60x18 memory result) {
        result = PRBMath.UD60x18({ value: PRBMath.mulDivFixedPoint(x.value, y.value) });
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (PRBMath.UD60x18 memory result) {
        result = PRBMath.UD60x18({ value: 3141592653589793238 });
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y) internal pure returns (PRBMath.UD60x18 memory result) {
        if (x.value == 0) {
            return PRBMath.UD60x18({ value: y.value == 0 ? SCALE : uint256(0) });
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(PRBMath.UD60x18 memory x, uint256 y) internal pure returns (PRBMath.UD60x18 memory result) {
        // Calculate the first iteration of the loop in advance.
        uint256 xValue = x.value;
        uint256 rValue = y & 1 > 0 ? xValue : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            xValue = PRBMath.mulDivFixedPoint(xValue, xValue);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                rValue = PRBMath.mulDivFixedPoint(rValue, xValue);
            }
        }
        result = PRBMath.UD60x18({ value: rValue });
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (PRBMath.UD60x18 memory result) {
        result = PRBMath.UD60x18({ value: SCALE });
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// Caveats:
    /// - The maximum fixed-point number permitted is 115792089237316195423570985008687907853269.984665640564039458.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        require(x.value < 115792089237316195423570985008687907853269984665640564039458);
        unchecked {
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.UD60x18({ value: PRBMath.sqrt(x.value * SCALE) });
        }
    }

    /// @notice Subtracts one unsigned 60.18-decimal fixed-point number from another one, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @param x The unsigned 60.18-decimal fixed-point number to subtract from.
    /// @param y The unsigned 60.18-decimal fixed-point number to subtract.
    /// @param result The result as an unsigned 60.18 decimal fixed-point number.
    function sub(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y) internal pure returns (PRBMath.UD60x18 memory result) {
        unchecked {
            require(x.value >= y.value);
            result = PRBMath.UD60x18({ value: x.value - y.value });
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(PRBMath.UD60x18 memory x) internal pure returns (uint256 result) {
        unchecked { result = x.value / SCALE; }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
// representation. When it does not, it is annonated in the function's NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE = 78156646155174841979727994598816262306175212592076161876661508869554232690281;

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Uses 128.128-bit fixed-point numbers, which is the most efficient way.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 128.128-bit fixed-point number.
    /// @return result The result as an unsigned 60x18 decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 128.128-bit fixed-point format.
            result = 0x80000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^127 and all magic factors are less than 2^129.
            if (x & 0x80000000000000000000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x40000000000000000000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDED) >> 128;
            if (x & 0x20000000000000000000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A7920) >> 128;
            if (x & 0x10000000000000000000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98364) >> 128;
            if (x & 0x8000000000000000000000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FE) >> 128;
            if (x & 0x4000000000000000000000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE9) >> 128;
            if (x & 0x2000000000000000000000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA40) >> 128;
            if (x & 0x1000000000000000000000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9544) >> 128;
            if (x & 0x800000000000000000000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679C) >> 128;
            if (x & 0x400000000000000000000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A011) >> 128;
            if (x & 0x200000000000000000000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5E0) >> 128;
            if (x & 0x100000000000000000000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939726) >> 128;
            if (x & 0x80000000000000000000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3E) >> 128;
            if (x & 0x40000000000000000000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B4) >> 128;
            if (x & 0x20000000000000000000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292027) >> 128;
            if (x & 0x10000000000000000000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FD) >> 128;
            if (x & 0x8000000000000000000000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAC) >> 128;
            if (x & 0x4000000000000000000000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7CA) >> 128;
            if (x & 0x2000000000000000000000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x1000000000000000000000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x800000000000000000000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1629) >> 128;
            if (x & 0x400000000000000000000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2C) >> 128;
            if (x & 0x200000000000000000000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A6) >> 128;
            if (x & 0x100000000000000000000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFF) >> 128;
            if (x & 0x80000000000000000000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2F0) >> 128;
            if (x & 0x40000000000000000000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737B) >> 128;
            if (x & 0x20000000000000000000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F07) >> 128;
            if (x & 0x10000000000000000000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44FA) >> 128;
            if (x & 0x8000000000000000000000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC824) >> 128;
            if (x & 0x4000000000000000000000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE51) >> 128;
            if (x & 0x2000000000000000000000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFD0) >> 128;
            if (x & 0x1000000000000000000000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x800000000000000000000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AE) >> 128;
            if (x & 0x400000000000000000000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CD) >> 128;
            if (x & 0x200000000000000000000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x100000000000000000000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AF) >> 128;
            if (x & 0x80000000000000000000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCF) >> 128;
            if (x & 0x40000000000000000000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0E) >> 128;
            if (x & 0x20000000000000000000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x10000000000000000000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94D) >> 128;
            if (x & 0x8000000000000000000000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33E) >> 128;
            if (x & 0x4000000000000000000000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26946) >> 128;
            if (x & 0x2000000000000000000000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388D) >> 128;
            if (x & 0x1000000000000000000000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D41) >> 128;
            if (x & 0x800000000000000000000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDF) >> 128;
            if (x & 0x400000000000000000000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77F) >> 128;
            if (x & 0x200000000000000000000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C3) >> 128;
            if (x & 0x100000000000000000000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E3) >> 128;
            if (x & 0x80000000000000000000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F2) >> 128;
            if (x & 0x40000000000000000000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA39) >> 128;
            if (x & 0x20000000000000000000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x10000000000000000000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x8000000000000000000 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x4000000000000000000 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x2000000000000000000 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D92) >> 128;
            if (x & 0x1000000000000000000 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x800000000000000000 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE545) >> 128;
            if (x & 0x400000000000000000 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x200000000000000000 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x100000000000000000 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x80000000000000000 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6E) >> 128;
            if (x & 0x40000000000000000 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B3) >> 128;
            if (x & 0x20000000000000000 > 0) result = (result * 0x1000000000000000162E42FEFA39EF359) >> 128;
            if (x & 0x10000000000000000 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AC) >> 128;

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where 2^n is the integer part and 1 is an extra bit to account
            //      for the fact that we initially set the result to 0.5 We implement this by subtracting from 127
            //      instead of 128.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because result * SCALE * 2^ip / 2^127 = result * SCALE / 2^(127 - ip), where ip is the integer
            // part and SCALE / 2^128 is what converts the result to the unsigned fixed-point format.
            result *= SCALE;
            result >>= (127 - (x >> 128));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2**256 and mod 2**256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256. Also prevents denominator == 0.
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2**256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2**256. Now that denominator is an odd number, it has an inverse modulo 2**256 such
            // that denominator * inv = 1 mod 2**256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inverse = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2**8
            inverse *= 2 - denominator * inverse; // inverse mod 2**16
            inverse *= 2 - denominator * inverse; // inverse mod 2**32
            inverse *= 2 - denominator * inverse; // inverse mod 2**64
            inverse *= 2 - denominator * inverse; // inverse mod 2**128
            inverse *= 2 - denominator * inverse; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2**256. Since the precoditions guarantee that the outcome is
            // less than 2**256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two queations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        require(SCALE > prod1);

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        require(x > type(int256).min);
        require(y > type(int256).min);
        require(denominator > type(int256).min);

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 resultUnsigned = mulDiv(ax, ay, ad);
        require(resultUnsigned <= uint256(type(int256).max));

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(resultUnsigned) : int256(resultUnsigned);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}