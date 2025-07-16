import 'package:flutter_test/flutter_test.dart';
import 'package:sat_quiz/services/content_renderer.dart';
import 'package:sat_quiz/models/content_block.dart';

void main() {
  group('ContentRenderer', () {
    group('renderMathContent', () {
      test('should render LaTeX fractions correctly', () {
        const latex = r'\frac{x+1}{y-2}';
        final result = ContentRenderer.renderMathContent(latex);
        expect(result, equals('(x+1)/(y-2)'));
      });

      test('should render LaTeX square roots correctly', () {
        const latex = r'\sqrt{x^2 + y^2}';
        final result = ContentRenderer.renderMathContent(latex);
        expect(result, equals('√(x^2 + y^2)'));
      });

      test('should convert LaTeX symbols to Unicode', () {
        const latex = r'\pi \alpha \beta \sum \int';
        final result = ContentRenderer.renderMathContent(latex);
        expect(result, equals('π α β ∑ ∫'));
      });

      test('should handle complex LaTeX expressions', () {
        const latex = r'\frac{\sqrt{x+1}}{\pi} \leq \infty';
        final result = ContentRenderer.renderMathContent(latex);
        expect(result, equals('(√(x+1))/(π) ≤ ∞'));
      });

      test('should handle MathML expressions', () {
        const mathml = '''
        <math>
          <mfrac>
            <mi>x</mi>
            <mi>y</mi>
          </mfrac>
        </math>
        ''';
        final result = ContentRenderer.renderMathContent(mathml);
        expect(result, equals('(x)/(y)'));
      });

      test('should handle MathML with square roots', () {
        const mathml = '''
        <math>
          <msqrt>
            <mi>x</mi>
          </msqrt>
        </math>
        ''';
        final result = ContentRenderer.renderMathContent(mathml);
        expect(result, equals('√(x)'));
      });

      test('should handle MathML with superscripts', () {
        const mathml = '''
        <math>
          <msup>
            <mi>x</mi>
            <mn>2</mn>
          </msup>
        </math>
        ''';
        final result = ContentRenderer.renderMathContent(mathml);
        expect(result, equals('x^2'));
      });

      test('should handle MathML with subscripts', () {
        const mathml = '''
        <math>
          <msub>
            <mi>x</mi>
            <mn>1</mn>
          </msub>
        </math>
        ''';
        final result = ContentRenderer.renderMathContent(mathml);
        expect(result, equals('x_1'));
      });

      test('should handle plain text without math formatting', () {
        const plainText = 'This is just regular text';
        final result = ContentRenderer.renderMathContent(plainText);
        expect(result, equals(plainText));
      });

      test('should handle malformed expressions gracefully', () {
        const malformed = r'\frac{incomplete';
        final result = ContentRenderer.renderMathContent(malformed);
        expect(result, contains('incomplete'));
      });

      test('should handle empty input', () {
        const empty = '';
        final result = ContentRenderer.renderMathContent(empty);
        expect(result, equals(''));
      });
    });

    group('renderTableContent', () {
      test('should render HTML table correctly', () {
        final tableData = {
          'html': '''
          <table>
            <thead>
              <tr><th>Name</th><th>Age</th></tr>
            </thead>
            <tbody>
              <tr><td>John</td><td>25</td></tr>
              <tr><td>Jane</td><td>30</td></tr>
            </tbody>
          </table>
          '''
        };

        final result = ContentRenderer.renderTableContent(tableData);

        expect(result, contains('Name'));
        expect(result, contains('Age'));
        expect(result, contains('John'));
        expect(result, contains('Jane'));
        expect(result, contains('25'));
        expect(result, contains('30'));
        expect(result, contains('|'));
        expect(result, contains('+'));
        expect(result, contains('-'));
      });

      test('should render structured table data correctly', () {
        final tableData = {
          'headers': ['Product', 'Price', 'Stock'],
          'rows': [
            ['Apple', '\$1.00', '50'],
            ['Banana', '\$0.50', '30'],
          ]
        };

        final result = ContentRenderer.renderTableContent(tableData);

        expect(result, contains('Product'));
        expect(result, contains('Price'));
        expect(result, contains('Stock'));
        expect(result, contains('Apple'));
        expect(result, contains('Banana'));
        expect(result, contains('\$1.00'));
        expect(result, contains('\$0.50'));
      });

      test('should render key-value table correctly', () {
        final tableData = {
          'data': {
            'Name': 'John Doe',
            'Email': 'john@example.com',
            'Phone': '123-456-7890'
          }
        };

        final result = ContentRenderer.renderTableContent(tableData);

        expect(result, contains('Name: John Doe'));
        expect(result, contains('Email: john@example.com'));
        expect(result, contains('Phone: 123-456-7890'));
      });

      test('should handle empty table data', () {
        final tableData = <String, dynamic>{};
        final result = ContentRenderer.renderTableContent(tableData);
        expect(result, contains('[Table:'));
      });

      test('should handle malformed HTML table', () {
        final tableData = {'html': '<table><tr><td>Incomplete'};

        final result = ContentRenderer.renderTableContent(tableData);
        expect(result, isNotEmpty);
      });

      test('should handle table with no headers', () {
        final tableData = {
          'html': '''
          <table>
            <tr><td>Data1</td><td>Data2</td></tr>
            <tr><td>Data3</td><td>Data4</td></tr>
          </table>
          '''
        };

        final result = ContentRenderer.renderTableContent(tableData);
        expect(result, contains('Data1'));
        expect(result, contains('Data2'));
        expect(result, contains('Data3'));
        expect(result, contains('Data4'));
      });
    });

    group('renderSvgContent', () {
      test('should extract title from SVG', () {
        const svg = '''
        <svg>
          <title>Chart showing sales data</title>
          <rect width="100" height="100"/>
        </svg>
        ''';

        final result = ContentRenderer.renderSvgContent(svg);
        expect(result, equals('[SVG: Chart showing sales data]'));
      });

      test('should extract description from SVG when no title', () {
        const svg = '''
        <svg>
          <desc>A simple rectangle</desc>
          <rect width="100" height="100"/>
        </svg>
        ''';

        final result = ContentRenderer.renderSvgContent(svg);
        expect(result, equals('[SVG: A simple rectangle]'));
      });

      test('should extract dimensions when no title or description', () {
        const svg = '''
        <svg width="200" height="150">
          <rect width="100" height="100"/>
        </svg>
        ''';

        final result = ContentRenderer.renderSvgContent(svg);
        expect(result, equals('[SVG Image: 200x150]'));
      });

      test('should provide generic description for SVG without metadata', () {
        const svg = '''
        <svg>
          <rect width="100" height="100"/>
        </svg>
        ''';

        final result = ContentRenderer.renderSvgContent(svg);
        expect(result, equals('[SVG Image]'));
      });

      test('should handle malformed SVG gracefully', () {
        const svg = '<svg><rect';
        final result = ContentRenderer.renderSvgContent(svg);
        expect(result, equals('[SVG Image]'));
      });

      test('should handle empty SVG input', () {
        const svg = '';
        final result = ContentRenderer.renderSvgContent(svg);
        expect(result, equals('[SVG Image]'));
      });
    });

    group('renderMixedContent', () {
      test('should render mixed content blocks correctly', () {
        final blocks = [
          ContentBlock.text('This is a question about '),
          ContentBlock.math(r'\frac{x}{y}'),
          ContentBlock.text(' and the following table:'),
          ContentBlock.table('', metadata: {
            'headers': ['X', 'Y'],
            'rows': [
              ['1', '2'],
              ['3', '4']
            ]
          }),
          ContentBlock.svg('<svg><title>Graph</title></svg>'),
        ];

        final result = ContentRenderer.renderMixedContent(blocks);

        expect(result, contains('This is a question about'));
        expect(result, contains('(x)/(y)'));
        expect(result, contains('and the following table:'));
        expect(result, contains('X'));
        expect(result, contains('Y'));
        expect(result, contains('[SVG: Graph]'));
      });

      test('should handle empty content blocks list', () {
        final blocks = <ContentBlock>[];
        final result = ContentRenderer.renderMixedContent(blocks);
        expect(result, equals(''));
      });

      test('should handle single content block', () {
        final blocks = [ContentBlock.text('Single block')];
        final result = ContentRenderer.renderMixedContent(blocks);
        expect(result, equals('Single block'));
      });

      test('should handle content blocks with image', () {
        final blocks = [
          ContentBlock.text('Here is an image: '),
          ContentBlock.image('image.png', metadata: {'alt': 'Sample Image'}),
        ];

        final result = ContentRenderer.renderMixedContent(blocks);
        expect(result, contains('Here is an image:'));
        expect(result, contains('[Image: Sample Image]'));
      });

      test('should handle table block without metadata', () {
        final blocks = [
          ContentBlock.text('Table without metadata: '),
          ContentBlock.table('table data'),
        ];

        final result = ContentRenderer.renderMixedContent(blocks);
        expect(result, contains('Table without metadata:'));
        expect(result, contains('[Table]'));
      });
    });

    group('error handling', () {
      test('should handle null or invalid input gracefully', () {
        // Test with various edge cases that might cause errors
        expect(() => ContentRenderer.renderMathContent(''), returnsNormally);
        expect(() => ContentRenderer.renderTableContent({}), returnsNormally);
        expect(() => ContentRenderer.renderSvgContent(''), returnsNormally);
        expect(() => ContentRenderer.renderMixedContent([]), returnsNormally);
      });

      test('should provide fallback for complex math expressions', () {
        const complexMath = r'\begin{matrix} a & b \\ c & d \end{matrix}';
        final result = ContentRenderer.renderMathContent(complexMath);
        expect(result, isNotEmpty);
      });

      test('should handle deeply nested LaTeX structures', () {
        const nested = r'\frac{\frac{a}{b}}{\frac{c}{d}}';
        final result = ContentRenderer.renderMathContent(nested);
        expect(result, contains('('));
        expect(result, contains(')'));
        expect(result, contains('/'));
      });
    });

    group('performance tests', () {
      test('should handle large content efficiently', () {
        final largeBlocks = List.generate(
            100, (i) => ContentBlock.text('Block $i with some content'));

        final stopwatch = Stopwatch()..start();
        final result = ContentRenderer.renderMixedContent(largeBlocks);
        stopwatch.stop();

        expect(result, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds,
            lessThan(1000)); // Should complete within 1 second
      });

      test('should handle large table efficiently', () {
        final largeTable = {
          'headers': List.generate(10, (i) => 'Column $i'),
          'rows': List.generate(
              50, (i) => List.generate(10, (j) => 'Row $i Col $j'))
        };

        final stopwatch = Stopwatch()..start();
        final result = ContentRenderer.renderTableContent(largeTable);
        stopwatch.stop();

        expect(result, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds,
            lessThan(1000)); // Should complete within 1 second
      });
    });
  });
}
