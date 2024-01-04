function print() {
    console.log("test test test")
}

$(document).ready(function(){
    $(".press").on("click", print)
});
