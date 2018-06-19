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
        shopSandwich[0].sandwichName = &quot;100: Ham & Swiss&quot;;
        shopSandwich[0].sandwichDesc = &quot;Ham Swiss Mustard Rye&quot;;
        shopSandwich[0].calories = &quot;450 calories&quot;;
        shopSandwich[0].price = 5;
        shopSandwich[0].availableQuantity = 200;

        shopSandwich[1].sandwichID = 1;
        shopSandwich[1].sandwichName = &quot;101: Turkey & Pepperjack&quot;;
        shopSandwich[1].sandwichDesc = &quot;Turkey Pepperjack Mayo White Bread&quot;;
        shopSandwich[1].calories = &quot;500 calories&quot;;
        shopSandwich[1].price = 5;
        shopSandwich[1].availableQuantity = 200;

        shopSandwich[2].sandwichID = 2;
        shopSandwich[2].sandwichName = &quot;102: Roast Beef & American&quot;;
        shopSandwich[2].sandwichDesc = &quot;Roast Beef Havarti Horseradish White Bread&quot;;
        shopSandwich[2].calories = &quot;600 calories&quot;;
        shopSandwich[2].price = 5;
        shopSandwich[2].availableQuantity = 200;

        shopSandwich[3].sandwichID = 3;
        shopSandwich[3].sandwichName = &quot;103: Reuben&quot;;
        shopSandwich[3].sandwichDesc = &quot;Corned Beef Sauerkraut Swiss Rye&quot;;
        shopSandwich[3].calories = &quot;550 calories&quot;;
        shopSandwich[3].price = 5;
        shopSandwich[3].availableQuantity = 200;

        shopSandwich[4].sandwichID = 4;
        shopSandwich[4].sandwichName = &quot;104: Italian&quot;;
        shopSandwich[4].sandwichDesc = &quot;Salami Peppers Provolone Oil Vinegar White&quot;;
        shopSandwich[4].calories = &quot;500 calories&quot;;
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
            return ( &quot;wrong ID&quot;, &quot;wrong ID&quot;, &quot;zero&quot;, 0);
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

    function getCartLength() constant returns (uint)
    {
        return cart[msg.sender].length;
    }

    function readFromCart(uint _spot) constant returns (string)
    {
        return cart[msg.sender][_spot].notes;
    }

    function emptyCart() public
    {
        delete cart[msg.sender];
    }

}