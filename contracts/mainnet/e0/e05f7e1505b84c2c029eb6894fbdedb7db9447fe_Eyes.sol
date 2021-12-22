//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";

contract Eyes is Trait {
  // Skin view
  // Mouse: 0
  string public constant MOUSE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWckJCScnJzx8fGYJxp/AAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCgIsLTYCXl2EUjIJRMGAAAKbZAC/5M7/QAAAAAElFTkSuQmCC";
  string public constant MOUSE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWckJCScnJzx8fGYJxp/AAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCgIsLTYCdnWEUjIJRMGAAAHzHACMa7IPxAAAAAElFTkSuQmCC";
  string public constant MOUSE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWckJCScnJzx8fGYJxp/AAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCgIsLTYCdl2EUjIJRMGAAAJHNACkBjKxHAAAAAElFTkSuQmCC";
  string public constant MOUSE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAD8RkZGw/zx8fFFHVXFAAAAAXRSTlMAQObYZgAAACJJREFUOMtjYBi8wP7/ART+/19f/6Op4D/AMApGwSgYKAAA+5EG+o56Gh4AAAAASUVORK5CYII=";
  string public constant MOUSE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAE/5Pz/+hoZe3CQjAAAAAXRSTlMAQObYZgAAABtJREFUOMtjYBhCgIMDTUBNjZCKUTAKRgHtAAB+8QBtvTcAMwAAAABJRU5ErkJggg==";
  string public constant MOUSE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEUAAAAkJCRXyFKEAAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKAZ4P//AcoyZhgFwxQAACR0AjJvfSwqAAAAAElFTkSuQmCC";

  // Frog: 1
  string public constant FROG_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWcAAABCpkz///+XoPGRAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBg0YAEXmsAFXoZRMApGwSAGAJ86AYhDlf2iAAAAAElFTkSuQmCC";
  string public constant FROG_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEUAAAAAAABCpkz///9ZYjdQAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBg0YAEXmkABO8MoGAWjYBADACvZASKoINImAAAAAElFTkSuQmCC";
  string public constant FROG_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVhYmwAAABCpkz///8p9twwAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBg0YAEXmkABL8MoGAWjYBADAEGrASg0BSMWAAAAAElFTkSuQmCC";
  string public constant FROG_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAAQujUVCpkxbHzrDAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBg0YAEXmkAAK8MoGAWjYBADALAEAQBNGbSAAAAAAElFTkSuQmCC";
  string public constant FROG_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHAOPfNB7fbmA8zv7oAAAAAXRSTlMAQObYZgAAABtJREFUOMtjYBg0QIEDTWCGGiEVo2AUjIKBBADbLwEPsGTK8wAAAABJRU5ErkJggg==";
  string public constant FROG_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVrdEccEwC5FntbAAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKA24P//Acp6zjAKhjsAAIyMAubQmKY3AAAAAElFTkSuQmCC";

  // Cats: 2
  string public constant CAT_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEV0ADMICAjW4cj17uQ4AAAAAXRSTlMAQObYZgAAABZJREFUOMtjYBjeQEWFYRSMglFAIwAA9xwASXm4vVAAAAAASUVORK5CYII=";
  string public constant CAT_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAAIICAjW4chWtdgHAAAAAXRSTlMAQObYZgAAABZJREFUOMtjYBjeQEKCYRSMglFAIwAApigAMYl5xA8AAAAASUVORK5CYII=";
  string public constant CAT_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAOQICAjW4cg2xUsqAAAAAXRSTlMAQObYZgAAABZJREFUOMtjYBjeQEWCYRSMglFAIwAAzqgAPQRpQ1IAAAAASUVORK5CYII=";
  string public constant CAT_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVzADHzkhJnCg09AAAAAXRSTlMAQObYZgAAABJJREFUKM9jYBgQkMYwCoYFAAC4VgBnaf6kIQAAAABJRU5ErkJggg==";
  string public constant CAT_3D =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWfiYGBgt+L///9ibcCbAAAAAXRSTlMAQObYZgAAAB5JREFUOMtjYBhW4P9/NP7r62gif+wZRsEoGAXUAQCX2Ab61dcG7QAAAABJRU5ErkJggg==";
  string public constant CAT_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHAMzzUjr4koPwf4VCAAAAAXRSTlMAQObYZgAAABtJREFUOMtjYBhWQIEDTWCGGiEVo2AUjAJyAQCTdwEPtoqJgAAAAABJRU5ErkJggg==";
  string public constant CAT_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEUAAAAICAhtdupNAAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKAj4P//AcpKYxgFwwIAAFgNAmXWxHedAAAAAElFTkSuQmCC";

  // Ape: 3
  string public constant APE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEV7+wMAAACSayD///8/JDF/AAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCQGMBmoDJBYZRMApGwYABAF4KAc2JOLBoAAAAAElFTkSuQmCC";
  string public constant APE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWcAAACSayD////l64lvAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCQGMBmoBMAcMoGAWjYMAAALlcAVV93WgeAAAAAElFTkSuQmCC";
  string public constant APE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVhYmwAAACSayD///9bvaTOAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCQGMBmoDMBYZRMApGwYABAAnaAbU/MvXGAAAAAElFTkSuQmCC";
  string public constant APE_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAEqCXhuSayBzqykqAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBhCQGMBmoBIAMMoGAWjYMAAAC0sAS1SowumAAAAAElFTkSuQmCC";
  string public constant APE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWffNB5PoNv//PdcxyH/AAAAAXRSTlMAQObYZgAAAB5JREFUOMtjYBg64D8QoIpcX4Ou5A/DKBgFo4BeAABeJQd7/5unYgAAAABJRU5ErkJggg==";
  string public constant APE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVwAMPfNB/fb2FvgwzdAAAAAXRSTlMAQObYZgAAABtJREFUOMtjYBhCQEEBTWDGDEIqRsEoGAW0AwDvEwGxXm8ZoQAAAABJRU5ErkJggg==";
  string public constant APE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVqZWMoHACkYH8mAAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKAZ4P//AcrKYRgFwxQAAI43AmtGeoLrAAAAAElFTkSuQmCC";

  // Alien: 4
  string public constant ALIEN_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAOoJDAdnzujtq9nGAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBjKQEUFTUBCgmEUjIJRQC8AAKXTAHkKAFKsAAAAAElFTkSuQmCC";
  string public constant ALIEN_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAKoICAhsyOJ1xWj1AAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBjKQEICTUBFhWEUjIJRQC8AAKQ7AHlAkZAkAAAAAElFTkSuQmCC";
  string public constant ALIEN_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVwANQICAhsyOI5MQBWAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBjKQEIFTUBFgmEUjIJRQC8AAKUHAHlRv0sRAAAAAElFTkSuQmCC";
  string public constant ALIEN_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHAM5BuNpWwN7KSNqmAAAAAXRSTlMAQObYZgAAABpJREFUOMtjYBjKQEMDTUBEhGEUjIJRQC8AAKZbAHm+C5+oAAAAAElFTkSuQmCC";
  string public constant ALIEN_3D =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVlLWfiR0xHx+L8/v9h5aJlAAAAAXRSTlMAQObYZgAAAB5JREFUOMtjYBhC4P9/NP7112gif+wZRsEoGAX0AgCE5Qb6uWgeRgAAAABJRU5ErkJggg==";
  string public constant ALIEN_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAFzeVmXmgYyfcOAVAAAAAXRSTlMAQObYZgAAACJJREFUOMtjYBhCgIMDTUBNDU1gxgw0AQUFhlEwCkYBjQAANawBzdOo8sAAAAAASUVORK5CYII=";
  string public constant ALIEN_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVya3UICAiZn1B1AAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKA94P//AcpKYxgFwwsAAG2RAmVHLjXYAAAAAElFTkSuQmCC";

  // Doge: 5
  string public constant DOGE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAANUVEQ7///+UYrkZAAAAAXRSTlMAQObYZgAAABZJREFUOMtjYBjEQIUAfxSMglEwoAAAB+cASbvRsD4AAAAASUVORK5CYII=";
  string public constant DOGE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAAH0VEQ7////gJiQQAAAAAXRSTlMAQObYZgAAABZJREFUOMtjYBjEQIIAfxSMglEwoAAAsVAAMYYGv/kAAAAASUVORK5CYII=";
  string public constant DOGE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEV0AFEVEQ7///9FdOUhAAAAAXRSTlMAQObYZgAAABhJREFUOMtjYBjEQAKNr8IwCkbBKBhEAADcNAA9lvR/RAAAAABJRU5ErkJggg==";
  string public constant DOGE_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEUAAACfdzgbVBGtAAAAAXRSTlMAQObYZgAAABRJREFUKM9jYKA6YIMxEhhGwXAHAMNOAGfViymQAAAAAElFTkSuQmCC";
  string public constant DOGE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVx+wP/AABBquz8/v/7RaQZAAAAAXRSTlMAQObYZgAAAB9JREFUOMtjYBi04D8QoIpcf42m5I89wygYBaNgwAAAHVsG+hdSEVQAAAAASUVORK5CYII=";
  string public constant DOGE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEUAABz/QUH/cnKceMWeAAAAAXRSTlMAQObYZgAAAB1JREFUOMtjYBg8QAGdPwNNYIYCAR2jYBSMAnoCABoqAbGPkLppAAAAAElFTkSuQmCC";
  string public constant DOGE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVya3UfGhWbBPmKAAAAAXRSTlMAQObYZgAAABdJREFUKM9jYKA24P//AcpKYxgFwx0AAJiZAmUBXFhvAAAAAElFTkSuQmCC";

  // Front view
  // Mouse: 0
  string public constant FRONT_MOUSE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAYSURBVCjPY2AgEsyZA8Fw8FEFgkfBcAYA3bAEmxgUpywAAAAASUVORK5CYII=";
  string public constant FRONT_MOUSE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAYSURBVCjPY2AgEsyZA8FwoPIRgkfBcAYA3BYEm2WQB0sAAAAASUVORK5CYII=";
  string public constant FRONT_MOUSE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAdSURBVCjPY2AgEsyZA8FwoPKRgeGjCrHaR8HQBADc4wSbx3hv2QAAAABJRU5ErkJggg==";
  string public constant FRONT_MOUSE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAADx8fFGw/z8RkZ76pEBAAAAAXRSTlMAQObYZgAAABdJREFUCNdjYAAD0VAgERUPYrEyDCYAALi7AT4MkX99AAAAAElFTkSuQmCC";
  string public constant FRONT_MOUSE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAD+hob5Pz8OwnIiAAAAAXRSTlMAQObYZgAAABVJREFUCNdjYEAAFhYgISkJYw0KAAAlXQBDsjfRKgAAAABJRU5ErkJggg==";
  string public constant FRONT_MOUSE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAeSURBVCjPY2AgBBgZGBgYVKCcOwhxFRUIHgXDGQAABmMBkrRf8jEAAAAASUVORK5CYII=";

  // Frog: 1
  string public constant FRONT_FROG_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAABCpkz///8AAADaoYegAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYAhgZWBg2MDNMDgBAKTJARGvt+qEAAAAAElFTkSuQmCC";
  string public constant FRONT_FROG_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAABCpkwAAAD///8qussDAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYAhgZWBg2MDNMDgBAKTJARGvt+qEAAAAAElFTkSuQmCC";
  string public constant FRONT_FROG_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAABCpkwAAAD///8qussDAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYAhgZWBg2MDHMDgBAKaRARSCVSMWAAAAAElFTkSuQmCC";
  string public constant FRONT_FROG_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAABCpkwujUVVHvfnAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYAhgZWBgWMDFMDgBAJqhAQBfDkj7AAAAAElFTkSuQmCC";
  string public constant FRONT_FROG_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAADfbmDfNB6638WMAAAAAXRSTlMAQObYZgAAABZJREFUCNdjYBBgYWBgSJEEEmDWIAMAYxwApt1kpUkAAAAASUVORK5CYII=";
  string public constant FRONT_FROG_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAAAcEwDRtKJJAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYGBg4P/AwFfAQBsAAIZyAX7ot6HTAAAAAElFTkSuQmCC";

  // Cats: 2
  string public constant FRONT_CAT_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAADW4cgICAgpWG32AAAAAXRSTlMAQObYZgAAABFJREFUCNdjYMAJJCQYBh4AABl4ADERYRJzAAAAAElFTkSuQmCC";
  string public constant FRONT_CAT_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAAICAjW4cjBKskuAAAAAXRSTlMAQObYZgAAABFJREFUCNdjYMAJJCQYBh4AABl4ADERYRJzAAAAAElFTkSuQmCC";
  string public constant FRONT_CAT_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAADW4cgICAgpWG32AAAAAXRSTlMAQObYZgAAABFJREFUCNdjYMAJJFQYBh4AAB+oAD1GfLEsAAAAAElFTkSuQmCC";
  string public constant FRONT_CAT_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAADzkhKiK+2WAAAAAXRSTlMAQObYZgAAABBJREFUCNdjYEAFbAkMVAUAH+AAZ1iIvc8AAAAASUVORK5CYII=";
  string public constant FRONT_CAT_3D =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD///9gt+LiYGCclyvXAAAAAXRSTlMAQObYZgAAABhJREFUCNdjYMAGQkOBRGYtkAgRZRhQAAAHagH68ks+IQAAAABJRU5ErkJggg==";
  string public constant FRONT_CAT_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAD4koPzUjrXizT8AAAAAXRSTlMAQObYZgAAABVJREFUCNdjYMAGBFiARIokjDWAAABWOACmNAJ9WgAAAABJRU5ErkJggg==";
  string public constant FRONT_CAT_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAeSURBVCjPY2CgHDAyMDAwcEA5P+DCHBwQPAqGMAAAC6oBIm0YoIMAAAAASUVORK5CYII=";

  // Ape: 3
  string public constant FRONT_APE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAACSayD///8AAABjE7LuAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEAAkQAgobOBYTABALRUAUE6qUrJAAAAAElFTkSuQmCC";
  string public constant FRONT_APE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAACSayAAAAD///+TCP5NAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEAAkQAgobOBYTABALRUAUE6qUrJAAAAAElFTkSuQmCC";
  string public constant FRONT_APE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAACSayAAAAD///+TCP5NAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEAAkQAgofOAYTABAM70AXFIS3QeAAAAAElFTkSuQmCC";
  string public constant FRONT_APE_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAACSayCCXhvR8cEyAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEAAkQAgobGAYTABAKk4AS2OnR7CAAAAAElFTkSuQmCC";
  string public constant FRONT_APE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD//PffNB5PoNu2dNPXAAAAAXRSTlMAQObYZgAAABdJREFUCNdjYECA0FAgkfkFxAphGCQAAH9nArGt+abTAAAAAElFTkSuQmCC";
  string public constant FRONT_APE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAADfb2HfNB9IBLvPAAAAAXRSTlMAQObYZgAAABVJREFUCNdjYEAAAQEgkZICYw0KAACTlAEJt/qpQQAAAABJRU5ErkJggg==";
  string public constant FRONT_APE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAAAoHAB1TvPKAAAAAXRSTlMAQObYZgAAABNJREFUCNdjYAAD/g8MbAcYaAAAmdsBxjfxqA8AAAAASUVORK5CYII=";

  // Alien: 4
  string public constant FRONT_ALIEN_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAABnzugJDAfufAhvAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEADEhJAQkWFYZAAAEIEAHmk+RO7AAAAAElFTkSuQmCC";
  string public constant FRONT_ALIEN_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAAICAhsyOKWHuTVAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEADEhJAQkWFYZAAAEIEAHmk+RO7AAAAAElFTkSuQmCC";
  string public constant FRONT_ALIEN_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAAICAhsyOKWHuTVAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEADEipAQkWCYZAAAEJAAHnqcWUsAAAAAElFTkSuQmCC";
  string public constant FRONT_ALIEN_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAABWwN5BuNpNaNzWAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYEADIiJAQkODYZAAAEHcAHnnfXiLAAAAAElFTkSuQmCC";
  string public constant FRONT_ALIEN_3D =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD8/v/iR0xHx+LiC8udAAAAAXRSTlMAQObYZgAAABhJREFUCNdjYECA0FAgkVkLJEJEGQYJAAAbJAH6EljucAAAAABJRU5ErkJggg==";
  string public constant FRONT_ALIEN_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAADmgYzeVmU+WfbBAAAAAXRSTlMAQObYZgAAABtJREFUCNdjYEAAFhYgISkJJFJSgISAAMPAAwCdDQEjJ/SyKQAAAABJRU5ErkJggg==";
  string public constant FRONT_ALIEN_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAAAAAA+4qcQAAAAAnRSTlMAAHaTzTgAAAAeSURBVCjPY2AgGTAyMDAwcEA5P+DCHBwQPAqGEwAAHtsBIq1KNLoAAAAASUVORK5CYII=";

  // Doge: 5
  string public constant FRONT_DOGE_RIGHT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAD///8VEQ7dSuz9AAAAAXRSTlMAQObYZgAAABBJREFUCNdjYIAACSgebAAAHMAAMYYQwVYAAAAASUVORK5CYII=";
  string public constant FRONT_DOGE_LEFT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAAVEQ7///9tmZX7AAAAAXRSTlMAQObYZgAAABBJREFUCNdjYIAACSgebAAAHMAAMYYQwVYAAAAASUVORK5CYII=";
  string public constant FRONT_DOGE_CROSSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAAVEQ7///9tmZX7AAAAAXRSTlMAQObYZgAAABJJREFUCNdjYIAACSBWYRh8AAAjsAA9lDVa0QAAAABJRU5ErkJggg==";
  string public constant FRONT_DOGE_CLOSED =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAACfdzgbVBGtAAAAAXRSTlMAQObYZgAAABFJREFUCNdjYACCBAY2BhoBACSWAGeG8raLAAAAAElFTkSuQmCC";
  string public constant FRONT_DOGE_3D =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAADFBMVEUAAAD8/v//AABBquxVNP1bAAAAAXRSTlMAQObYZgAAABhJREFUCNdjYACD0FAgkVkLJEJEGQYTAAAlAQH6aSoA1gAAAABJRU5ErkJggg==";
  string public constant FRONT_DOGE_LASER =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAgMAAABm5xBfAAAACVBMVEUAAAD/cnL/QUFzoqIbAAAAAXRSTlMAQObYZgAAABdJREFUCNdjYGAQYADiFCCRAmYxDCoAAJtQAQnk4ZJQAAAAAElFTkSuQmCC";
  string public constant FRONT_DOGE_SUN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgAQMAAAAhR2qPAAAABlBMVEUAAAAfGhVv7UOyAAAAAXRSTlMAQObYZgAAABRJREFUCNdjYGBg4P/AwJbAQBsAAH4qAWZN2x1aAAAAAElFTkSuQmCC";

  constructor() {
    _tiers = [3100, 6100, 8100, 9300, 9800, 9900, 10000];
  }

  function getName(uint256 traitIndex)
    public
    pure
    override
    returns (string memory name)
  {
    if (traitIndex == 0) {
      return "Right";
    } else if (traitIndex == 1) {
      return "Left";
    } else if (traitIndex == 2) {
      return "Crossed";
    } else if (traitIndex == 3) {
      return "Sun"; 
    } else if (traitIndex == 4) {
      return "Closed";
    } else if (traitIndex == 5) {
      return "3D";
    } else if (traitIndex == 6) {
      return "Laser";
    }
  }

  function _getLayer(
    uint256 traitIndex,
    uint256 layerIndex,
    string memory prefix
  ) internal view override returns (string memory layer) {
    if (traitIndex == 0) {
      return _indexedLayer(layerIndex, prefix, "RIGHT");
    } else if (traitIndex == 1) {
      return _indexedLayer(layerIndex, prefix, "LEFT");
    } else if (traitIndex == 2) {
      return _indexedLayer(layerIndex, prefix, "CROSSED");
    } else if (traitIndex == 3) {
      return _indexedLayer(layerIndex, prefix, "SUN");
    } else if (traitIndex == 4) {
      return _indexedLayer(layerIndex, prefix, "CLOSED");
    } else if (traitIndex == 5) {
      return _indexedLayer(layerIndex, prefix, "3D");
    } else if (traitIndex == 6) {
      return _indexedLayer(layerIndex, prefix, "LASER");
    }
  }

  function _getLayerPrefix(uint256 layerIndex)
    internal
    pure
    override
    returns (string memory prefix)
  {
    if (layerIndex == 0) {
      return "FROG_";
    } else if (layerIndex == 1) {
      return "MOUSE_";
    } else if (layerIndex == 2) {
      return "APE_";
    } else if (layerIndex == 3) {
      return "CAT_";
    } else if (layerIndex == 4) {
      return "ALIEN_";
    } else if (layerIndex == 5) {
      return "DOGE_";
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./ITrait.sol";

abstract contract Trait is ITrait {
  bool internal _frontArmorTraitsExists = false;
  uint256[] internal _tiers;

  /*
  READ FUNCTIONS
  */

  function getSkinLayer(uint256 traitIndex, uint256 layerIndex)
    public
    view
    virtual
    override
    returns (string memory layer)
  {
    return _getLayer(traitIndex, layerIndex, "");
  }

  function getFrontLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    virtual
    override
    returns (string memory frontLayer)
  {
    return _getLayer(traitIndex, layerIndex, "FRONT_");
  }

  function getFrontArmorLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    virtual
    override
    returns (string memory frontArmorLayer)
  {
    return _getLayer(traitIndex, layerIndex, "FRONT_ARMOR_");
  }

  function sampleTraitIndex(uint256 rand)
    external
    view
    virtual
    override
    returns (uint256 index)
  {
    rand = rand % 10000;
    for (uint256 i = 0; i < _tiers.length; i++) {
      if (rand < _tiers[i]) {
        return i;
      }
    }
  }

  function _layer(string memory prefix, string memory name)
    internal
    view
    virtual
    returns (string memory trait)
  {
    bytes memory sig = abi.encodeWithSignature(
      string(abi.encodePacked(prefix, name, "()")),
      ""
    );
    (bool success, bytes memory data) = address(this).staticcall(sig);
    return success ? abi.decode(data, (string)) : "";
  }

  function _indexedLayer(
    uint256 layerIndex,
    string memory prefix,
    string memory name
  ) internal view virtual returns (string memory layer) {
    return
      _layer(
        string(abi.encodePacked(prefix, _getLayerPrefix(layerIndex))),
        name
      );
  }

  function _getLayerPrefix(uint256)
    internal
    view
    virtual
    returns (string memory prefix)
  {
    return "";
  }

  /*
  PURE VIRTUAL FUNCTIONS
  */

  function _getLayer(
    uint256 traitIndex,
    uint256 layerIndex,
    string memory prefix
  ) internal view virtual returns (string memory layer);

  /*
  MODIFIERS
  */
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrait {
  function getSkinLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory layer);

  function getFrontLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory frontLayer);

  function getFrontArmorLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory frontArmorLayer);

  function getName(uint256 traitIndex)
    external
    view
    returns (string memory name);

  function sampleTraitIndex(uint256 rand) external view returns (uint256 index);
}