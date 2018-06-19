pragma solidity ^0.4.15;

contract EthPixel {
    struct Pixel {
        bytes32 color;
        uint256 amount;
        address holder;
    }

    Pixel [1000000] public pixels;

    event PixelBought(uint256 coordinates, bytes32 color, uint256 amount, address holder, address boughtFrom);

    function buyPixel(uint256 _coordinates, bytes32 _color) payable returns (bool) {
        require(msg.value > 0);
        require(_color.length > 0);

        Pixel memory pixel = pixels[_coordinates];

        require(msg.value > pixel.amount);
        require(msg.sender != pixel.holder);

        if (pixel.amount > 0) {
            pixel.holder.transfer(pixel.amount);
        }

        pixels[_coordinates] = Pixel({
            color: _color,
            amount: msg.value,
            holder: msg.sender
        });

        PixelBought(_coordinates, _color, msg.value, msg.sender, pixel.holder);

        return true;
    }
}