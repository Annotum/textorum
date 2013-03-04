({
    //appDir: "./",
    baseUrl: "lib/",
    dir: "dist/",
    //Comment out the optimize line if you want
    //the code minified by UglifyJS.
    //optimize: "none",
    removeCombined: true,
    preserveLicenseComments: false,
    wrap: {
	startFile: ["lib/fragments/start.frag"],
	endFile: ["lib/fragments/end.frag"]
    },
    paths: {
    },
    
    modules: [
        {
            name: "textorum"
        }
    ]
    , namespace: 'textorum'
})
