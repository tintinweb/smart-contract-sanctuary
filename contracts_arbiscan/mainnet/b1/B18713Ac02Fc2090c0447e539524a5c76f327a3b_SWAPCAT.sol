/**
 *Submitted for verification at arbiscan.io on 2021-09-27
*/

pragma solidity ^0.4.20;

// 😸 WWW.SWAP.CAT 😸
//
// a simple DEX for fixed price token offers directly from wallet to wallet
//
// users can set up erc20 tokens for sale for any other erc20
//
// funds stay in users wallets, dex contract gets a spending allowance
//
// payments go directly into the sellers wallet
//
// this DEX takes no fees
//
// mostly useful to provide stablecoin liquidity or sell tokens for a premium
//
// offers have to be adjusted by the user if prices change
//




// we need the erc20 interface to access the tokens details

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    // no return value on transfer and transferFrom to tolerate old erc20 tokens
    // we work around that in the buy function by checking balance twice
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function decimals() external view returns (uint256);
    function symbol() external view returns (string);
    function name() external view returns (string);

}





contract SWAPCAT {

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// lets make mappings to store offer data

    mapping (uint24 => uint256) internal price;
    mapping (uint24 => address) internal offertoken;
    mapping (uint24 => address) internal buyertoken;
    mapping (uint24 => address) internal seller;
    uint24 internal offercount;


// admin address, receives donations and can move stuck funds, nothing else    
    address internal admin = 0xc965E082B0082449047501032F0E9e7F3DC5Cc12;






////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// set up your erc20 offer. give token addresses and the price in baseunits
// to change a price simply call this again with the changed price + offerid

function makeoffer(address _offertoken, address _buyertoken, uint256 _price, uint24 _offerid) public returns (uint24) {

// if no offerid is given a new offer is made, if offerid is given only the offers price is changed if owner matches
        if(_offerid==0)
                    {
                    _offerid=offercount;
                    offercount++;seller[_offerid]=msg.sender;
                    offertoken[_offerid]=_offertoken;
                    buyertoken[_offerid]=_buyertoken;
                    }
                    else
                    {
                    require(seller[_offerid]==msg.sender,"only original seller can change offer!");
                    }
        price[_offerid]=_price;

// returns the offerid
        return _offerid;
    }
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////









////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// delete an offer

function deleteoffer(uint24 _offerid) public returns (string) {
        require(seller[_offerid]==msg.sender,"only original seller can change offer!");
        delete seller[_offerid];
        delete offertoken[_offerid];
        delete buyertoken[_offerid];
        delete price[_offerid];
        return "offer deleted";
    }
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// return the total number of offers to loop through all offers
// its the web frontends job to keep track of offers

function getoffercount() public view returns (uint24){ return offercount-1;}

//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////






////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// get a tokens name, symbol and decimals 

    function tokeninfo(address _tokenaddr) public view returns (uint256, string, string) {
        IERC20 tokeni = IERC20(_tokenaddr);
        return (tokeni.decimals(),tokeni.symbol(),tokeni.name());
        }   
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////











////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// get a single offers details

    function showoffer(uint24 _offerid) public view returns (address, address, address, uint256, uint256) {
        

        IERC20 offertokeni = IERC20(offertoken[_offerid]);


// get offertokens balance and allowance, whichever is lower is the available amount        
        uint256 availablebalance = offertokeni.balanceOf(seller[_offerid]);
        uint256 availableallow = offertokeni.allowance(seller[_offerid],address(this));

        if(availableallow<availablebalance){availablebalance = availableallow;}

        return (offertoken[_offerid],buyertoken[_offerid],seller[_offerid],price[_offerid],availablebalance);
        
    }   
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// return the price in buyertokens for the specified amount of offertokens

function pricepreview(uint24 _offerid, uint256 _amount) public view returns (uint256) {
        IERC20 offertokeni = IERC20(offertoken[_offerid]);
        return  _amount * price[_offerid] / (uint256(10) ** offertokeni.decimals())+1;
    }
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////






////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// return the amount in offertokens for the specified amount of buyertokens, for debugging

//function pricepreviewreverse(uint24 _offerid, uint256 _amount) public view returns (uint256) {
//        IERC20 offertokeni = IERC20(offertoken[_offerid]);
//        return  _amount * (uint256(10) ** offertokeni.decimals()) / price[_offerid];
//    }
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////






////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// the actual exchange function
// the buyer must bring the price correctly to ensure no frontrunning / changed offer
// if the offer is changed in meantime, it will not execute

function buy(uint24 _offerid, uint256 _offertokenamount, uint256 _price) public returns (string) {

        IERC20 offertokeninterface = IERC20(offertoken[_offerid]);
        IERC20 buyertokeninterface = IERC20(buyertoken[_offerid]);


// given price is being checked with recorded data from mappings
       require(price[_offerid] == _price,"offer price wrong");


// calculate the price of the order
        uint256 buyertokenAmount =  _offertokenamount * _price / (uint256(10) ** offertokeninterface.decimals())+1;


////// these 4 checks have been spared out since the final check suffices, this save ~50000 gas
////        // check if the buyers allowance and balance are right
////                require(buyertokeninterface.allowance(msg.sender, address(this)) >= buyertokenAmount, "Check the buyers token allowance");
////                require(buyertokeninterface.balanceOf(msg.sender) >= buyertokenAmount,"buyer not enough to pay");
////        // check if the sellers allowance and balance are right        
////                require(offertokeninterface.allowance(seller[_offerid], address(this)) >= _offertokenamount, "Check the sellers token allowance");
////                require(offertokeninterface.balanceOf(seller[_offerid]) >= _offertokenamount,"seller not enough on stock");
  
        
// some old erc20 tokens give no return value so we must work around by getting their balance before and after the exchange        
        uint256 oldbuyerbalance = buyertokeninterface.balanceOf(msg.sender);
        uint256 oldsellerbalance = offertokeninterface.balanceOf(seller[_offerid]);


// finally do the exchange        
        buyertokeninterface.transferFrom(msg.sender,seller[_offerid], buyertokenAmount);
        offertokeninterface.transferFrom(seller[_offerid],msg.sender,_offertokenamount);


// now check if the balances changed on both accounts.
// we do not check for exact amounts since some tokens behave differently with fees, burnings, etc
// we assume if both balances are higher than before all is good
        require(oldbuyerbalance > buyertokeninterface.balanceOf(msg.sender),"buyer error");
        require(oldsellerbalance > offertokeninterface.balanceOf(seller[_offerid]),"seller error");
        return "tokens exchanged. ENJOY!";
    }
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////












////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// in case someone wrongfully directly sends erc20 to this contract address, the admin can move them out
function losttokens(address token) public {
        IERC20 tokeninterface = IERC20(token);
        tokeninterface.transfer(admin,tokeninterface.balanceOf(address(this)));
}
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// straight ether payments to this contract are considered donations. thank you!
function () public payable {admin.transfer(address(this).balance);        }
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////






}