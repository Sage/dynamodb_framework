
[1mFrom:[0m /dynamodb_framework/lib/dynamodb_framework/dynamodb_query.rb @ line 20 DynamoDbFramework::Query#method_missing:

    [1;34m17[0m: [32mdef[0m [1;34mmethod_missing[0m(name, *arguments)
    [1;34m18[0m:   parts = []
    [1;34m19[0m:   parts << { [35mtype[0m: [33m:field[0m, [35mvalue[0m: name }
 => [1;34m20[0m:   binding.pry
    [1;34m21[0m:   arguments.each [32mdo[0m |a|
    [1;34m22[0m:     parts << a
    [1;34m23[0m:   [32mend[0m
    [1;34m24[0m:   parts
    [1;34m25[0m: [32mend[0m

