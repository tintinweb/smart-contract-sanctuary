pragma solidity ^0.4.11;

contract mortal
{
    address owner;

    function mortal() { owner = msg.sender; }
    function kill() { if(msg.sender == owner) selfdestruct(owner); }
}

contract SandwichShop is mortal
{

    struct Sandwich
    {
        uint sandwichID;
        string sandwichName;
        string sandwichDesc;
        string calories;
        uint price;
        uint availableQuantity;
    }

    struct OrderedSandwich
    {
        uint sandID;
        string notes;
        uint price;
    }

    Sandwich[5] shopSandwich;
    mapping( address => OrderedSandwich[] ) public cart; 

    function SandwichShop() public
    {
        shopSandwich[0].sandwichID = 0;
        shopSandwich[0].sandwichName = "100: Ham & Swiss";
        shopSandwich[0].sandwichDesc = "Ham Swiss Mustard Rye";
        shopSandwich[0].calories = "450 calories";
        shopSandwich[0].price = 5;
        shopSandwich[0].availableQuantity = 200;

        shopSandwich[1].sandwichID = 1;
        shopSandwich[1].sandwichName = "101: Turkey & Pepperjack";
        shopSandwich[1].sandwichDesc = "Turkey Pepperjack Mayo White Bread";
        shopSandwich[1].calories = "500 calories";
        shopSandwich[1].price = 5;
        shopSandwich[1].availableQuantity = 200;

        shopSandwich[2].sandwichID = 2;
        shopSandwich[2].sandwichName = "102: Roast Beef & American";
        shopSandwich[2].sandwichDesc = "Roast Beef Havarti Horseradish White Bread";
        shopSandwich[2].calories = "600 calories";
        shopSandwich[2].price = 5;
        shopSandwich[2].availableQuantity = 200;

        shopSandwich[3].sandwichID = 3;
        shopSandwich[3].sandwichName = "103: Reuben";
        shopSandwich[3].sandwichDesc = "Corned Beef Sauerkraut Swiss Rye";
        shopSandwich[3].calories = "550 calories";
        shopSandwich[3].price = 5;
        shopSandwich[3].availableQuantity = 200;

        shopSandwich[4].sandwichID = 4;
        shopSandwich[4].sandwichName = "104: Italian";
        shopSandwich[4].sandwichDesc = "Salami Peppers Provolone Oil Vinegar White";
        shopSandwich[4].calories = "500 calories";
        shopSandwich[4].price = 5;
        shopSandwich[4].availableQuantity = 200;
    }

    function getMenu() constant returns (string, string, string, string, string)
    {
        return (shopSandwich[0].sandwichName, shopSandwich[1].sandwichName,
                shopSandwich[2].sandwichName, shopSandwich[3].sandwichName,
                shopSandwich[4].sandwichName );
    }

    function getSandwichInfoCaloriesPrice(uint _sandwich) constant returns (string, string, string, uint)
    {
        if( _sandwich > 4 )
        {
            return ( "wrong ID", "wrong ID", "zero", 0);
        }
        else
        {
            return (shopSandwich[_sandwich].sandwichName, shopSandwich[_sandwich].sandwichDesc,
                shopSandwich[_sandwich].calories, shopSandwich[_sandwich].price);
        }
    }

    function addToCart(uint _orderID, string _notes) returns (uint)
    {
        OrderedSandwich memory newOrder;
        newOrder.sandID = _orderID;
        newOrder.notes = _notes;
        newOrder.price = shopSandwich[_orderID].price;

        return cart[msg.sender].push(newOrder);
    }

    function getCartLength(address _curious) constant returns (uint)
    {
        return cart[_curious].length;
    }

    function readFromCart(address _curious, uint _spot) constant returns (string)
    {
        return cart[_curious][_spot].notes;
    }

    function emptyCart() public
    {
        delete cart[msg.sender];
    }

}