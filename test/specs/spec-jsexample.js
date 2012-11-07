define(function(require) {
    
pavlov.specify("Textorum Example", function(){

    describe("A feature that is being described from within a requirejs test", function(){

        var foo;

        before(function(){
            foo = "bar";
        });

        after(function(){
            foo = "baz";
        });

        it("can be specified like so", function(){
            assert(foo).equals('bar');
        });

	it("is boringly true", function() {
	    console.log("Boring");
	    assert(1).equals(1);
	});
    });

});
});
