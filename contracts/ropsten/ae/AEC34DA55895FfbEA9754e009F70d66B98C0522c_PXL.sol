/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//        :::::::::       :::::::::::       :::    :::       ::::::::::       :::  
//       :+:    :+:          :+:           :+:    :+:       :+:              :+:   
//      +:+    +:+          +:+            +:+  +:+        +:+              +:+    
//     +#++:++#+           +#+             +#++:+         +#++:++#         +#+     
//    +#+                 +#+            +#+  +#+        +#+              +#+      
//   #+#                 #+#           #+#    #+#       #+#              #+#       
//  ###             ###########       ###    ###       ##########       ########## 

contract PXL {

    struct SoldRect {
        address payable owner;
        uint price;
        uint x0;
        uint y0;
        uint x1;
        uint y1;
    }
    
    struct Rect {
        uint aux;
        uint x0;
        uint y0;
        uint x1;
        uint y1;
    }
    
    struct ColorRect {
        uint red;
        uint green;
        uint blue;
        uint x0;
        uint y0;
        uint x1;
        uint y1;
    }
    
    uint public newindex = 1;
    uint public colorindex = 1;
    
    mapping (uint => ColorRect) public colorStack;
    mapping (uint => SoldRect) public rectStack;
    mapping (uint => uint[]) public children;
    mapping (address => uint) public pendingReturns;
    
    constructor () {
        rectStack[0].owner = payable(address(0));
        rectStack[0].price = 1;
        rectStack[0].x0 = 0;
        rectStack[0].y0 = 0;
        rectStack[0].x1 = 1023;
        rectStack[0].y1 = 1023;
        colorStack[0].x0 = 0;
        colorStack[0].y0 = 0;
        colorStack[0].x1 = 1023;
        colorStack[0].y1 = 1023;
        colorStack[0].red = 255;
        colorStack[0].green = 255;
        colorStack[0].blue = 255;
    }
    
    function buyRect(Rect[] memory rectangles, Rect memory total) public payable {
        require(rectangles.length > 0, "rien a acheter");
        uint expenses = 0;
        uint nbpixels = 0;
        for(uint i = 0; i < rectangles.length; i++) {
            Rect memory tobuy = rectangles[i];
            SoldRect memory parent = rectStack[tobuy.aux];
            require(rectangles[i].aux < newindex,"vente innexistante");
            require(tobuy.x1 >= tobuy.x0 && tobuy.y1 >= tobuy.y0, "format rectangle incompatible");
            require(total.x0 <= tobuy.x0 && total.y0 <= tobuy.y0 && total.x1 >= tobuy.x1 && total.y1 >= tobuy.y1,"rectangle en dehors du total");
            require(parent.x0 <= tobuy.x0 && parent.y0 <= tobuy.y0 && parent.x1 >= tobuy.x1 && parent.y1 >= tobuy.y1,"rectangle a acheter en dehors de celui indique");
            for(uint j = 0; j < children[tobuy.aux].length; j++) {
                SoldRect memory child = rectStack[children[tobuy.aux][j]];
                require(child.x0 > tobuy.x1 || child.x1 < tobuy.x0 || child.y0 > tobuy.y1 || child.y1 < tobuy.y0,"deja vendu");
            }
            nbpixels += (1 + tobuy.x1 - tobuy.x0)*(1 + tobuy.y1 - tobuy.y0);
            expenses += parent.price * (1 + tobuy.x1 - tobuy.x0)*(1 + tobuy.y1 - tobuy.y0);
            pendingReturns[parent.owner] += parent.price * (1 + tobuy.x1 - tobuy.x0)*(1 + tobuy.y1 - tobuy.y0);
            children[tobuy.aux].push(newindex);
        }
        require(nbpixels == (1 + total.x1 - total.x0) * (1 + total.y1 - total.y0), "assemblage incomplet");
        require(msg.value >= expenses, "solde insuffisant");
        rectStack[newindex].owner = payable(msg.sender);
        pendingReturns[payable(msg.sender)] += (msg.value - expenses);
        rectStack[newindex].x0 = total.x0;
        rectStack[newindex].y0 = total.y0;
        rectStack[newindex].x1 = total.x1;
        rectStack[newindex].y1 = total.y1;
        rectStack[newindex].price = total.aux;
        newindex++;
    }
    
    function getRectPrice(Rect[] memory rectangles, Rect memory total) public view returns (uint) {
        require(rectangles.length > 0, "rien a acheter");
        uint expenses = 0;
        uint nbpixels = 0;
        for(uint i = 0; i < rectangles.length; i++) {
            Rect memory tobuy = rectangles[i];
            SoldRect memory parent = rectStack[tobuy.aux];
            require(rectangles[i].aux < newindex,"vente innexistante");
            require(tobuy.x1 >= tobuy.x0 && tobuy.y1 >= tobuy.y0, "format rectangle incompatible");
            require(total.x0 <= tobuy.x0 && total.y0 <= tobuy.y0 && total.x1 >= tobuy.x1 && total.y1 >= tobuy.y1,"rectangle en dehors du total");
            require(parent.x0 <= tobuy.x0 && parent.y0 <= tobuy.y0 && parent.x1 >= tobuy.x1 && parent.y1 >= tobuy.y1,"rectangle a acheter en dehors de celui indique");
            for(uint j = 0; j < children[tobuy.aux].length; j++) {
                SoldRect memory child = rectStack[children[tobuy.aux][j]];
                require(child.x0 > tobuy.x1 || child.x1 < tobuy.x0 || child.y0 > tobuy.y1 || child.y1 < tobuy.y0,"deja vendu");
            }
            nbpixels += (1 + tobuy.x1 - tobuy.x0)*(1 + tobuy.y1 - tobuy.y0);
            expenses += parent.price * (1 + tobuy.x1 - tobuy.x0)*(1 + tobuy.y1 - tobuy.y0);
        }
        require(nbpixels == (1 + total.x1 - total.x0) * (1 + total.y1 - total.y0), "assemblage incomplet");
        return expenses;
    }
    
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
    
    function colorize(ColorRect[] memory painting, uint id) public {
        SoldRect memory parent = rectStack[id];
        require(msg.sender == parent.owner, "rectangle non possede");
        require(children[id].length == 0,"non completement possede");
        for(uint i = 0; i < painting.length; i++) {
            require(parent.x0 <= painting[i].x0 && parent.y0 <= painting[i].y0 && parent.x1 >= painting[i].x1 && parent.y1 >= painting[i].y1,"out of cadre");
            colorStack[colorindex] = painting[i];
            colorindex++;
        }
    }
    
    function getPixelRect(uint x, uint y, uint id) public view returns (uint pixelrect){
        require(x < 1024 && y < 1024, "pixel innexistant");
        for(uint i = 0; i < children[id].length; i++) {
            SoldRect memory child = rectStack[children[id][i]];
            if(child.x0 <= x && x <= child.x1 && child.y0 <= y && y <= child.y1){
                return getPixelRect(x,y,children[id][i]);
            }
        }
        return id;
    }
    
}